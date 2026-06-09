from pydantic import BaseModel, EmailStr
from typing import Optional, List
import datetime

class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    role: Optional[str] = "farmer"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: str
    full_name: str
    email: EmailStr
    role: str
    is_approved: bool
    created_at: datetime.datetime

    class Config:
        from_attributes = True

class UserUpdateRole(BaseModel):
    role: str

class UserUpdateApproval(BaseModel):
    is_approved: bool

class ScanOut(BaseModel):
    id: str
    user_id: str
    image_url: str
    disease: str
    confidence: float
    severity: str
    created_at: datetime.datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserOut

class TokenData(BaseModel):
    email: Optional[str] = None

class UserUpdateProfile(BaseModel):
    full_name: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

class PasswordResetRequest(BaseModel):
    email: EmailStr

class PasswordResetConfirm(BaseModel):
    token: str
    new_password: str
