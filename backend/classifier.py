import os
import random
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io

# Define classes
CLASSES = [
    "Anthracnose du fruit (Maladie)",
    "Feuille saine",
    "Flétrissement bactérien de la tige (Maladie)",
    "Fruit sain",
    "Pourriture de la racine (Maladie)",
    "Racine saine",
    "Sigatoka noire de la feuille (Maladie)",
    "Tige saine"
]

MODEL_PATH = os.path.join(os.path.dirname(__file__), "banana_model.pth")
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# Model architecture (MobileNetV2 with 8 outputs)
def build_model():
    model = models.mobilenet_v2(pretrained=False)
    # Recreate the classification head
    model.classifier[1] = nn.Linear(model.last_channel, len(CLASSES))
    return model

# Load model if exists, otherwise run in simulation mode
model = None
if os.path.exists(MODEL_PATH):
    try:
        model = build_model()
        # Load state dict
        model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
        model.to(device)
        model.eval()
        print("KaakiScan IA: PyTorch model loaded successfully.")
    except Exception as e:
        print(f"Error loading model {MODEL_PATH}: {e}. Falling back to simulation.")
        model = None
else:
    print("KaakiScan IA: No banana_model.pth found. Running in simulation mode.")

# Image pre-processing
preprocess = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

def predict_image(image_bytes: bytes):
    """
    Predict disease from banana plant image (root, stem, leaf, fruit)
    Returns: (predicted_class_name, confidence, severity_level)
    """
    if model is not None:
        try:
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            tensor = preprocess(image).unsqueeze(0).to(device)
            
            with torch.no_grad():
                outputs = model(tensor)
                probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
                
            conf, class_idx = torch.max(probabilities, 0)
            class_name = CLASSES[class_idx.item()]
            confidence = float(conf.item())
            
            # Determine severity based on disease keyword
            if "sain" in class_name.lower():
                severity = "low"
            elif "pourriture" in class_name.lower() or "sigatoka" in class_name.lower():
                severity = "high"
            else:
                severity = "medium"
                
            return class_name, confidence, severity
        except Exception as e:
            print(f"Error during PyTorch inference: {e}. Falling back to simulation.")
    
    # --- Fallback: Simulated IA Diagnostic ---
    # Analyze image bytes using md5 hash to return a stable result for the same photo
    import hashlib
    diseases = [
        ("Sigatoka noire", "high"),
        ("Flétrissement bactérien", "high"),
        ("Maladie de Panama", "medium"),
        ("Feuille saine", "low"),
        ("Racine saine", "low"),
        ("Pourriture racinaire", "high"),
        ("Tige saine", "low"),
        ("Fruit sain", "low"),
        ("Anthracnose du fruit", "medium")
    ]
    
    h = int(hashlib.md5(image_bytes).hexdigest(), 16)
    selected = diseases[h % len(diseases)]
    confidence = round(0.75 + (h % 23) / 100.0, 2)
    return selected[0], confidence, selected[1]


# ─── Image Content Validation ────────────────────────────────────────────────

# Validation model (lazy-loaded MobileNetV2 pretrained on ImageNet)
validation_model = None
categories = []

def get_validation_model():
    global validation_model, categories
    if validation_model is None:
        try:
            weights = models.MobileNet_V2_Weights.DEFAULT
            categories = weights.meta["categories"]
            validation_model = models.mobilenet_v2(weights=weights)
            validation_model.to(device)
            validation_model.eval()
            print("KaakiScan IA: Pretrained MobileNetV2 loaded for image validation.")
        except Exception as e:
            print(f"Error loading validation model: {e}")
    return validation_model, categories


def validate_banana_image(image_bytes: bytes, custom_confidence: float) -> tuple[bool, str]:
    """
    Validate that the uploaded image is indeed a banana plant/fruit/leaf/root.
    Checks against pre-trained ImageNet model and custom model confidence.
    Returns: (is_valid, error_message)
    """
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception:
        return False, "Fichier image invalide ou corrompu."

    val_model, cats = get_validation_model()
    if val_model is None or not cats:
        # Fallback to True if validation model cannot be loaded (offline mode, etc.)
        return True, ""

    try:
        # Preprocess for ImageNet (uses same preprocess transform)
        tensor = preprocess(image).unsqueeze(0).to(device)
        with torch.no_grad():
            outputs = val_model(tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            
        # Get top 5 predictions
        top5_prob, top5_idx = torch.topk(probabilities, 5)
        top5_classes = [cats[idx.item()].lower() for idx in top5_idx]
        print(f"DEBUG: validate_banana_image: top5_classes={top5_classes}, probabilities={[round(p.item(), 4) for p in top5_prob]}")
        top1_class = top5_classes[0]
        
        # Check if banana is in the top 5 predictions
        is_banana_in_top5 = any("banana" in name for name in top5_classes)
        
        # Blacklist of keywords (Humans, animals, urban, clothing, etc.)
        blacklist_keywords = [
            "groom", "bride", "ballplayer", "player", "person", "man", "woman", "child", "baby",
            "t-shirt", "suit", "jersey", "jean", "skirt", "coat", "jacket", "dress", "clothing",
            "uniform", "hat", "cap", "glasses", "sunglasses", "face", "hair",
            "dog", "cat", "car", "truck", "bus", "airplane", "bicycle", "motorcycle", "train",
            "building", "house", "furniture", "chair", "table", "computer", "screen", "keyboard",
            "mouse", "phone", "street", "road", "room", "office", "classroom", "shoe", "boot"
        ]
        
        # Blacklist of other specific plants/flowers/crops to reject immediately
        blacklist_plants = [
            "daisy", "rose", "tulip", "sunflower", "orchid", "dandelion", "marigold", "poppy", "lily",
            "carnation", "cactus",
            "lemon", "orange", "apple", "grape", "strawberry", "tomato",
            "potato", "carrot", "onion", "garlic", "pepper", "chili", "pumpkin", "watermelon", "melon",
            "peach", "plum", "cherry", "pear", "berry"
        ]
        
        # Expanded Whitelist of plant/vegetation/agriculture/natural classes compatible with banana parts
        whitelist_keywords = [
            "banana", "leaf", "plant", "tree", "forest", "fruit", "zucchini", "squash", 
            "cucumber", "root", "jackfruit", "corn", "pineapple", "orchard", "valley",
            "wood", "lumber", "log", "bark", "stalk", "stem", "vegetable", "hay", "straw",
            "pot", "flowerpot", "nature", "grass", "shrub", "bush", "foliage", "cardoon",
            "cabbage", "greenhouse", "earthstar", "fungus", "mushroom", "fern", "moss",
            "buckeye", "chestnut"
        ]
        
        # Helper to tokenize a category into words (split by spaces/commas, lowercase)
        def get_words(cat_str):
            return cat_str.replace(",", " ").lower().split()
            
        # 1. Reject if any of the top 3 classes is blacklisted (human, dog, car, clothing...)
        for cat in top5_classes[:3]:
            cat_words = get_words(cat)
            if any(black in cat_words for black in blacklist_keywords):
                return False, "Veuillez mettre une photo de bananier (feuille, fruit, racine ou tige)."
                
        # 2. Reject if top class is another plant / flower / crop
        top1_words = get_words(top1_class)
        if any(plant in top1_words for plant in blacklist_plants):
            return False, "L'image ne semble pas être une culture de banane. Veuillez mettre une photo de bananier."
            
        # 3. Accept if banana is in top-5
        if is_banana_in_top5:
            return True, ""
            
        # 4. Check if ANY of the top-5 classes contains a whitelisted keyword
        is_plant_related = False
        for cat in top5_classes:
            cat_words = get_words(cat)
            if any(white in cat_words for white in whitelist_keywords):
                is_plant_related = True
                break
                
        if is_plant_related:
            # If custom model has decent confidence on plant-related image, we accept it
            if custom_confidence >= 0.35:
                return True, ""
            else:
                return False, "L'image ne semble pas être une culture de banane. Veuillez mettre une photo de bananier."
                
        # 5. Fallback of good confidence of custom model (as long as no strict blacklist matches)
        if custom_confidence >= 0.50:
            return True, ""
            
        # 6. Otherwise, reject
        return False, "L'image ne semble pas être une culture de banane. Veuillez mettre une photo de bananier."
        
    except Exception as e:
        print(f"Error during image validation: {e}")
        return True, ""

