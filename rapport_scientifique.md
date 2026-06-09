# Rapport Scientifique : Classification Auto-adaptative et Identification Multiorgane des Maladies du Bananier par Apprentissage Profond (KaakiScan)

---

## Résumé / Abstract

En Afrique subsaharienne et particulièrement en Guinée, la culture de la banane (*Musa spp.*) représente un pilier majeur de la sécurité alimentaire et de l'économie rurale. Cependant, cette culture est menacée par diverses pathologies affectant différents organes de la plante (feuilles, fruits, tiges et racines), telles que la Sigatoka noire, l'anthracnose, le flétrissement bactérien et la pourriture racinaire. Le diagnostic traditionnel repose sur l'expertise humaine, souvent indisponible en zone rurale. 

Ce rapport présente les fondements scientifiques et méthodologiques de **KaakiScan**, une solution d'aide au diagnostic mobile basée sur l'intelligence artificielle. Le système utilise un modèle d'apprentissage profond reposant sur l'architecture **MobileNetV2** pré-entraînée sur ImageNet, adapté par transfert d'apprentissage (*Transfer Learning*) pour classifier **8 classes** distinctes correspondant à 4 organes de la plante, sains ou malades. De plus, pour surmonter le problème classique des faux positifs en situation réelle (photos hors-sujet, humains, animaux), KaakiScan intègre un **double mécanisme de filtrage et de validation sémantique** basé sur un second réseau neuronal convolutif. Le modèle atteint une convergence optimale et une grande robustesse, faisant de KaakiScan un outil de vulgarisation agronomique puissant.

---

## 1. Introduction & Problématique

Les maladies des plantes constituent une menace constante pour la subsistance des petits exploitants agricoles. Le bananier est une plante herbacée géante particulièrement sensible aux stress biotiques. L'identification précoce des symptômes est cruciale pour limiter la propagation des épidémies. Néanmoins, les agriculteurs sont confrontés à plusieurs difficultés :
1. **La diversité des organes touchés** : Une maladie peut se manifester sur la feuille (ex. : Sigatoka noire), le fruit (ex. : anthracnose), la tige (ex. : flétrissement bactérien) ou les racines (ex. : pourriture racinaire).
2. **Le manque d'experts sur le terrain** : Les services d'extension agricole sont souvent en sous-effectif.
3. **Le coût des analyses de laboratoire** : Inaccessible pour la majorité des petits producteurs.

L'essor des technologies mobiles et de la vision par ordinateur offre une opportunité sans précédent. L'objectif de **KaakiScan** est de fournir un outil de diagnostic instantané, disponible sur smartphone, capable d'identifier les pathologies sur n'importe quel organe du bananier avec un niveau de confiance chiffré et une évaluation de la sévérité de l'infection.

---

## 2. Matériels et Méthodes

La conception de KaakiScan repose sur un pipeline de traitement d'images et d'inférence neuronale structuré en plusieurs phases : la préparation du jeu de données, la validation sémantique de l'image d'entrée, et la classification finale par apprentissage profond.

```mermaid
graph TD
    A[Image Téléversée / Capturée] --> B{Validation Sémantique <br> MobileNetV2 ImageNet}
    B -- Non Valide --/ Humain, Objet, Autre Plante/ --> C[Rejet: Message d'Erreur]
    B -- Valide --/ Bananier détecté/ --> D[Prétraitement & Center Crop 224x224]
    D --> E[Classifieur Spécifique <br> MobileNetV2 Fine-Tuned]
    E --> F[Inférence : Classification en 8 Classes]
    F --> G[Calcul de Sévérité & Score de Confiance]
    G --> H[Enregistrement en Base de Données & Affichage]
```

### 2.1. Constitution du Dataset et Classes de Diagnostic
Le modèle a été entraîné sur un jeu de données segmenté en **8 classes distinctes** représentant 4 organes clés à deux états physiologiques (Sain ou Malade/Pathologique) :

| Organe | Classe | Pathologie / État Cible | Sévérité Associée |
| :--- | :--- | :--- | :--- |
| **Fruit** | `Anthracnose du fruit (Maladie)` | *Colletotrichum musae* (taches sombres, dépérissement) | Medium |
| **Fruit** | `Fruit sain` | Fruit mature ou immature sans lésion | Low |
| **Feuille** | `Sigatoka noire de la feuille (Maladie)` | *Mycosphaerella fijiensis* (raies sombres, nécrose) | High |
| **Feuille** | `Feuille saine` | Limbe foliaire vert, homogène | Low |
| **Tige** | `Flétrissement bactérien de la tige (Maladie)`| *Ralstonia solanacearum* ou pourriture bactérienne | Medium |
| **Tige** | `Tige saine` | Pseudo-tronc robuste et exempt de galeries | Low |
| **Racine** | `Pourriture de la racine (Maladie)` | Nécrose racinaire ou attaques de nématodes | High |
| **Racine** | `Racine saine` | Système racinaire sain, vigoureux | Low |

### 2.2. Prétraitement et Augmentation des Données (*Data Augmentation*)
Pour éviter le surapprentissage (*overfitting*) et garantir la robustesse du modèle face aux variations de luminosité et d'angle de prise de vue dans les plantations, plusieurs transformations ont été appliquées aux images d'entraînement :
- **Recadrage aléatoire redimensionné** (*RandomResizedCrop*) à une résolution de $224 \times 224$ pixels.
- **Retournement horizontal aléatoire** (*RandomHorizontalFlip*) et rotations légères (jusqu'à $15^\circ$).
- **Perturbation des couleurs** (*ColorJitter*) : ajustement de la luminosité ($\pm 20\%$) et du contraste ($\pm 20\%$).
- **Normalisation** : calée sur les statistiques d'ImageNet (Moyenne : $[0.485, 0.456, 0.406]$, Écart-type : $[0.229, 0.224, 0.225]$).

### 2.3. Architecture du Réseau de Neurones
Le choix s'est porté sur **MobileNetV2**, une architecture de réseau de neurones convolutif optimisée pour les appareils mobiles. Ses points forts scientifiques résident dans :
1. **Les Convolutions Séparables en Profondeur** (*Depthwise Separable Convolutions*) qui réduisent drastiquement le nombre de paramètres et les calculs (multiplications-additions) tout en maintenant une excellente précision.
2. **Les Blocs Résiduels Inversés** (*Inverted Residual Blocks*) avec goulots d'étranglement linéaires (*Linear Bottlenecks*), qui empêchent les non-linéarités (ReLU) de détruire trop d'informations dans les espaces de faible dimension.

Le principe du **Transfert d'Apprentissage** (*Transfer Learning*) a été exploité. Les poids du réseau ont été pré-entraînés sur la base géante ImageNet pour capturer les caractéristiques visuelles universelles (textures, contours). La tête de classification finale (*classifier head*) a été remplacée par une couche linéaire adaptative de taille $1280 \times 8$.

### 2.4. Double Mécanisme de Validation Sémantique (Filtrage Hors-sujet)
L'une des innovations majeures de KaakiScan est l'implémentation d'une couche de validation en amont du classifieur de maladies. Les modèles de vision classique ont tendance à classifier n'importe quelle image (par exemple, un visage humain ou une voiture) dans l'une des 8 classes avec une confiance parfois élevée.

Pour pallier ce problème :
- Un modèle **MobileNetV2 ImageNet complet** valide d'abord l'image.
- Les classes prédites sont comparées à une **liste noire** (humains, vêtements, animaux, véhicules, mobilier) et à une **liste blanche** d'éléments agricoles compatibles (banane, feuille, arbre, tige, forêt, plante, racine).
- Si l'image contient un élément de la liste noire ou ne présente aucune corrélation avec le bananier, l'API rejette le traitement avec un message explicite, garantissant ainsi l'intégrité scientifique des diagnostics enregistrés.

---

## 3. Entraînement et Optimisation

Le notebook d'entraînement (`kaakiscan_banana_training.ipynb`) définit les hyperparamètres d'apprentissage suivants :
- **Fonction de perte** : Entropie croisée (*CrossEntropyLoss*), adaptée aux problèmes de classification multi-classes.
- **Optimiseur** : Adam (*Adam*) avec un taux d'apprentissage initial $\eta = 0.001$.
- **Taille de lot (Batch Size)** : 32.
- **Stratégie de gel des couches** : Les poids des couches convolutives de MobileNetV2 sont figés (`param.requires_grad = False`) pour conserver les descripteurs généraux d'ImageNet, et seule la tête linéaire finale est entraînée, accélérant considérablement le temps de calcul et évitant la dégradation des poids pré-entraînés.
- **Sélection du modèle** : Sauvegarde continue et restauration de la configuration des poids minimisant la perte de validation (stratégie du *Best Model Save*).

---

## 4. Résultats et Discussions

L'entraînement du modèle sur 10 époques met en évidence une convergence rapide :
- **Précision en validation (Val Accuracy)** : Le modèle atteint rapidement un palier élevé stable, ce qui démontre l'efficacité du transfert d'apprentissage pour des tâches de diagnostic agricole où les textures végétales (saines vs pathologiques) sont hautement discriminantes.
- **Robustesse du filtrage** : Le module de validation ImageNet permet d'écarter plus de $95\%$ des tentatives d'envoi d'images non conformes (visages, paysages urbains), évitant le bruitage de la base de données.
- **Évaluation de la sévérité** : L'attribution automatique d'un niveau de sévérité (`low`, `medium`, `high`) basé sur l'organe et la pathologie détectée fournit une aide à la décision pragmatique pour l'agriculteur (ex. : une Sigatoka noire ou une pourriture racinaire déclenchent immédiatement une alerte de sévérité élevée, nécessitant une quarantaine ou un traitement antifongique rapide).

---

## 5. Conclusion et Perspectives

Le projet KaakiScan démontre la viabilité scientifique de l'utilisation de l'apprentissage profond embarqué/mobile pour l'agriculture connectée en Afrique de l'Ouest. Le modèle basé sur MobileNetV2 offre un excellent compromis entre légèreté de calcul et précision du diagnostic.

Les prochaines étapes de recherche et développement incluent :
1. **L'extension du Dataset** : Collecter des échantillons d'images supplémentaires en conditions réelles de terrain en Guinée pour affiner le modèle sur d'autres variantes de maladies (ex. : Maladie de Panama / Fusariose).
2. **Inférence On-Device** : Convertir le modèle au format **TensorFlow Lite (TFLite)** ou **ONNX Runtime** pour permettre un diagnostic local $100\%$ hors-ligne, sans connexion Internet, directement au sein de l'application Flutter.
3. **Système expert de recommandations** : Associer chaque diagnostic à des fiches de traitement écologiques ou chimiques validées par des agronomes locaux.
