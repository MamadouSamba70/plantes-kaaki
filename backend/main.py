import os
import shutil
import uuid
import datetime
from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from typing import List, Dict

from database import engine, Base, get_db
import models, schemas, auth, classifier

# In-memory store for reset tokens: {token: email}
_reset_tokens: Dict[str, str] = {}

# Initialize Database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="KaakiScan API", version="1.0.0")

# Enable CORS for Flutter app communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Directory to save uploaded scan images
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# Auto-seed the SuperAdmin user
@app.on_event("startup")
def seed_superadmin():
    db = next(get_db())
    try:
        admin_email = "sambrindiallo@gmail.com"
        admin = db.query(models.User).filter(models.User.email == admin_email).first()
        if not admin:
            hashed_pw = auth.get_password_hash("sambrindiallo@70")
            new_admin = models.User(
                id="superadmin_uid_00000",
                full_name="Super Administrateur",
                email=admin_email,
                hashed_password=hashed_pw,
                role="superadmin",
                is_approved=True,
                created_at=datetime.datetime.utcnow()
            )
            db.add(new_admin)
            db.commit()
            print("KaakiScan DB: SuperAdmin user sambrindiallo@gmail.com successfully seeded!")
    except Exception as e:
        print(f"Error seeding superadmin: {e}")
    finally:
        db.close()


# ─── Authentication Routes ────────────────────────────────────────────────────

@app.post("/api/register", response_model=schemas.UserOut)
def register(user_data: schemas.UserCreate, db: Session = Depends(get_db)):
    # Check if user already exists
    existing_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Un compte existe déjà avec cet e-mail."
        )
    
    hashed_password = auth.get_password_hash(user_data.password)
    user_id = f"uid_{uuid.uuid4().hex[:12]}"
    
    # Superadmin is approved automatically, others require validation
    is_approved = True if user_data.role == "superadmin" else False
    
    new_user = models.User(
        id=user_id,
        full_name=user_data.full_name,
        email=user_data.email,
        hashed_password=hashed_password,
        role=user_data.role,
        is_approved=is_approved,
        created_at=datetime.datetime.utcnow()
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


@app.post("/api/login", response_model=schemas.Token)
def login(form_data: schemas.UserLogin, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.email).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="E-mail ou mot de passe incorrect."
        )
        
    # Check if user is approved (except superadmin)
    if not user.is_approved and user.role != "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Votre compte est en attente de validation par l'administrateur."
        )
        
    access_token = auth.create_access_token(data={"sub": user.email})
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


# ─── Password Reset Routes ────────────────────────────────────────────────────

@app.post("/api/auth/forgot-password")
def forgot_password(data: schemas.PasswordResetRequest, db: Session = Depends(get_db)):
    """Generate a reset token for the given email. Always returns success to avoid email enumeration."""
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if user:
        token = uuid.uuid4().hex
        _reset_tokens[token] = data.email
        # In production, send token by email. For now, return it in response for dev use.
        print(f"[DEV] Password reset token for {data.email}: {token}")
        return {"message": "Un code de réinitialisation a été généré.", "dev_token": token}
    return {"message": "Si cet e-mail est enregistré, un code vous sera transmis via votre administrateur."}


@app.post("/api/auth/reset-password")
def reset_password(data: schemas.PasswordResetConfirm, db: Session = Depends(get_db)):
    """Consume a reset token and update the user's password."""
    email = _reset_tokens.get(data.token)
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code de réinitialisation invalide ou expiré."
        )
    if len(data.new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le nouveau mot de passe doit comporter au moins 6 caractères."
        )
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.hashed_password = auth.get_password_hash(data.new_password)
    db.commit()
    del _reset_tokens[data.token]  # invalidate token after use
    return {"message": "Mot de passe réinitialisé avec succès. Vous pouvez maintenant vous connecter."}


@app.put("/api/users/profile", response_model=schemas.UserOut)
def update_profile(
    profile_data: schemas.UserUpdateProfile,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    if profile_data.email and profile_data.email.strip().lower() != current_user.email.lower():
        existing_user = db.query(models.User).filter(models.User.email == profile_data.email.strip().lower()).first()
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Un compte existe déjà avec cet e-mail."
            )
        current_user.email = profile_data.email.strip().lower()
        
    if profile_data.full_name is not None and profile_data.full_name.strip():
        current_user.full_name = profile_data.full_name.strip()
        
    if profile_data.password is not None and profile_data.password:
        if len(profile_data.password) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Le mot de passe doit comporter au moins 6 caractères."
            )
        current_user.hashed_password = auth.get_password_hash(profile_data.password)
        
    db.commit()
    db.refresh(current_user)
    return current_user


# ─── Admin/SuperAdmin Routes ──────────────────────────────────────────────────

@app.get("/api/users/pending", response_model=List[schemas.UserOut])
def get_pending_users(current_user: models.User = Depends(auth.get_current_superadmin), db: Session = Depends(get_db)):
    return db.query(models.User).filter(models.User.is_approved == False, models.User.role != "superadmin").all()


@app.get("/api/users/approved", response_model=List[schemas.UserOut])
def get_approved_users(current_user: models.User = Depends(auth.get_current_superadmin), db: Session = Depends(get_db)):
    return db.query(models.User).filter(models.User.is_approved == True, models.User.role != "superadmin").all()


@app.put("/api/users/{uid}/approve", response_model=schemas.UserOut)
def approve_user(uid: str, current_user: models.User = Depends(auth.get_current_superadmin), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_approved = True
    db.commit()
    db.refresh(user)
    return user


@app.put("/api/users/{uid}/suspend", response_model=schemas.UserOut)
def suspend_user(uid: str, current_user: models.User = Depends(auth.get_current_superadmin), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.is_approved = False
    db.commit()
    db.refresh(user)
    return user


@app.put("/api/users/{uid}/role", response_model=schemas.UserOut)
def change_user_role(uid: str, role_data: schemas.UserUpdateRole, current_user: models.User = Depends(auth.get_current_superadmin), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    user.role = role_data.role
    db.commit()
    db.refresh(user)
    return user


@app.delete("/api/users/{uid}", status_code=204)
def delete_user(uid: str, current_user: models.User = Depends(auth.get_current_superadmin), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.id == uid).first()
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")
    db.delete(user)
    db.commit()
    return None


# ─── Diagnostic Scans Routes ──────────────────────────────────────────────────

@app.post("/api/scan", response_model=schemas.ScanOut)
async def perform_scan(
    image: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(get_db)
):
    scan_id = f"scan_{int(datetime.datetime.utcnow().timestamp() * 1000)}"
    file_extension = os.path.splitext(image.filename)[1] or ".jpg"
    file_name = f"{scan_id}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, file_name)
    
    # Read image contents
    contents = await image.read()
    
    # Analyze image using classifier model
    disease, confidence, severity = classifier.predict_image(contents)
    
    # Validate image is a banana culture (checks for humans, other plants, etc.)
    is_valid, err_msg = classifier.validate_banana_image(contents, confidence)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=err_msg
        )
        
    # Save image file locally
    with open(file_path, "wb") as f:
        f.write(contents)
    
    # Create web accessible image URL
    image_url = f"/uploads/{file_name}"
    
    new_scan = models.Scan(
        id=scan_id,
        user_id=current_user.id,
        image_url=image_url,
        disease=disease,
        confidence=confidence,
        severity=severity,
        created_at=datetime.datetime.utcnow()
    )
    
    db.add(new_scan)
    db.commit()
    db.refresh(new_scan)
    return new_scan


@app.get("/api/scans", response_model=List[schemas.ScanOut])
def get_user_scans(current_user: models.User = Depends(auth.get_current_active_user), db: Session = Depends(get_db)):
    return db.query(models.Scan).filter(models.Scan.user_id == current_user.id).order_by(models.Scan.created_at.desc()).all()


@app.get("/api/scans/all", response_model=List[schemas.ScanOut])
def get_all_scans(current_user: models.User = Depends(auth.get_current_active_user), db: Session = Depends(get_db)):
    # Experts, researchers, and superadmins can view all scans
    if current_user.role not in ["agronomist", "researcher", "superadmin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Action non autorisée pour ce rôle."
        )
    return db.query(models.Scan).order_by(models.Scan.created_at.desc()).all()


@app.delete("/api/scans/{scan_id}", status_code=204)
def delete_scan(scan_id: str, current_user: models.User = Depends(auth.get_current_active_user), db: Session = Depends(get_db)):
    scan = db.query(models.Scan).filter(models.Scan.id == scan_id).first()
    if not scan:
        raise HTTPException(status_code=404, detail="Scan introuvable.")
        
    # Allow deletion only by scan owner or superadmin
    if scan.user_id != current_user.id and current_user.role != "superadmin":
        raise HTTPException(status_code=403, detail="Non autorisé à supprimer ce scan.")
        
    # Delete image file from server
    try:
        img_name = os.path.basename(scan.image_url)
        img_path = os.path.join(UPLOAD_DIR, img_name)
        if os.path.exists(img_path):
            os.remove(img_path)
    except Exception as e:
        print(f"Error deleting image file: {e}")
        
    db.delete(scan)
    db.commit()
    return None
