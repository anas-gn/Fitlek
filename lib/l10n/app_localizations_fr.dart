// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get loginErrorEmptyEmail => 'Veuillez saisir votre adresse e-mail.';

  @override
  String get loginErrorEmptyPassword => 'Veuillez saisir votre mot de passe.';

  @override
  String get loginErrorInvalidToken => 'Jeton invalide reçu du serveur.';

  @override
  String get loginErrorMissingUserData =>
      'Les données utilisateur sont manquantes.';

  @override
  String get loginErrorIncompleteUserInfo =>
      'Informations utilisateur incomplètes.';

  @override
  String get loginErrorSocialAccount =>
      'Ce compte utilise la connexion Google ou Apple. Continuez avec votre méthode de connexion initiale ci-dessous.';

  @override
  String loginErrorCode(int code) {
    return 'Erreur de connexion ($code)';
  }

  @override
  String get loginErrorCheckConnection => 'Vérifiez votre connexion.';

  @override
  String loginErrorUnrecognizedRole(String role) {
    return 'Rôle non reconnu : $role';
  }

  @override
  String get loginErrorGoogleFailed =>
      'La connexion avec Google a échoué. Veuillez réessayer.';

  @override
  String get loginErrorAppleFailed =>
      'La connexion avec Apple a échoué. Veuillez réessayer.';

  @override
  String get loginErrorInvalidCredentials =>
      'E-mail ou mot de passe incorrect.';

  @override
  String get loginErrorSuspended => 'Ce compte est suspendu.';

  @override
  String get loginErrorFillAllFields => 'Veuillez remplir tous les champs.';

  @override
  String get loginErrorAccountNotFound =>
      'Aucun compte trouvé avec cet e-mail.';

  @override
  String get loginBadgeSignIn => 'CONNEXION';

  @override
  String get loginHeadingTitle => 'Bon retour';

  @override
  String get loginHeadingSubtitle =>
      'Connectez-vous pour accéder à votre espace et gérer vos activités.';

  @override
  String get loginEmailLabel => 'Adresse e-mail';

  @override
  String get loginEmailHint => 'votre@email.com';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginPasswordHint => 'Saisissez votre mot de passe';

  @override
  String get loginForgotPassword => 'Mot de passe oublié ?';

  @override
  String get loginCtaLogIn => 'SE CONNECTER';

  @override
  String get loginOr => 'OU';

  @override
  String get loginContinueGoogle => 'CONTINUER AVEC GOOGLE';

  @override
  String get loginContinueApple => 'CONTINUER AVEC APPLE';

  @override
  String get loginNotRegisteredYet => 'Pas encore inscrit ?';

  @override
  String get loginCreateAccount => 'CRÉER UN COMPTE';

  @override
  String get loginBackTo => 'Retour à l\'';

  @override
  String get loginBackToHome => 'accueil';

  @override
  String get loginSetPasswordErrorMinLength =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get loginSetPasswordErrorMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get loginSetPasswordErrorFailed =>
      'Impossible de définir le mot de passe.';

  @override
  String get loginSetPasswordErrorConnection => 'Erreur de connexion.';

  @override
  String get loginSetPasswordSuccessTitle => 'Mot de passe défini !';

  @override
  String get loginSetPasswordSuccessMessage =>
      'Vous pouvez désormais vous connecter avec votre e-mail et votre mot de passe.';

  @override
  String get loginSetPasswordDone => 'Terminé';

  @override
  String get loginSetPasswordTitle => 'Définir un mot de passe';

  @override
  String get loginSetPasswordSubtitle =>
      'Définissez un mot de passe facultatif pour pouvoir également vous connecter avec votre e-mail plus tard.';

  @override
  String get loginSetPasswordNewLabel => 'Nouveau mot de passe';

  @override
  String get loginSetPasswordConfirmLabel => 'Confirmer le mot de passe';

  @override
  String get loginSetPasswordSkip => 'Passer';

  @override
  String get loginSetPasswordSubmit => 'Définir le mot de passe';

  @override
  String get registerInterestsDialogTitle => 'Vos centres d\'intérêt';

  @override
  String get registerCancel => 'Annuler';

  @override
  String get registerContinue => 'Continuer';

  @override
  String get registerErrorSelectRole =>
      'Sélectionnez votre rôle pour continuer';

  @override
  String get registerErrorAcceptTerms =>
      'Vous devez accepter le cadre juridique et de conformité de Sirvya pour créer un compte.';

  @override
  String get registerErrorFirstNameRequired => 'Prénom requis';

  @override
  String get registerErrorLastNameRequired => 'Nom requis';

  @override
  String get registerErrorInvalidEmail => 'Adresse e-mail invalide';

  @override
  String get registerErrorHeightRequired => 'Taille requise';

  @override
  String get registerErrorInvalidHeight => 'Taille invalide';

  @override
  String get registerErrorInvalidWeight => 'Saisissez un poids valide en kg';

  @override
  String get registerErrorChooseInterest =>
      'Choisissez au moins un centre d\'intérêt (jusqu\'à 5)';

  @override
  String get registerErrorLocationRequired =>
      'Appuyez sur Utiliser ma position actuelle pour renseigner votre localisation';

  @override
  String get registerErrorChooseSpecialty =>
      'Veuillez sélectionner au moins une spécialité (jusqu\'à 5)';

  @override
  String get registerErrorPasswordTooShort =>
      'Mot de passe trop court (min. 6 caractères)';

  @override
  String get registerErrorPasswordsMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get registerErrorSelectGender =>
      'Sélectionnez votre genre pour continuer';

  @override
  String get registerErrorOtpLength =>
      'Saisissez le code de vérification à 6 chiffres envoyé par e-mail';

  @override
  String get registerErrorSendOtpFailed =>
      'Échec de l\'envoi du code de vérification';

  @override
  String get registerErrorServerUnreachable =>
      'Impossible de joindre le serveur';

  @override
  String get registerErrorInvalidOtp => 'Code de vérification invalide';

  @override
  String get registerErrorVerifyOtpNetwork =>
      'Erreur réseau lors de la vérification du code';

  @override
  String get registerErrorFailed => 'L\'inscription a échoué';

  @override
  String get registerErrorSelectRoleGoogle =>
      'Sélectionnez votre rôle avant de continuer avec Google.';

  @override
  String get registerErrorSelectRoleApple =>
      'Sélectionnez votre rôle avant de continuer avec Apple.';

  @override
  String get registerErrorAgreeTermsSocial =>
      'Veuillez accepter les conditions d\'utilisation pour vous inscrire.';

  @override
  String registerErrorUnrecognizedRole(String role) {
    return 'Rôle non reconnu : $role';
  }

  @override
  String get registerErrorGoogleFailed =>
      'L\'inscription avec Google a échoué. Veuillez réessayer.';

  @override
  String get registerErrorAppleFailed =>
      'L\'inscription avec Apple a échoué. Veuillez réessayer.';

  @override
  String get registerSuccessTitle => 'Compte créé !';

  @override
  String registerSuccessPendingApproval(String firstName) {
    return 'Bienvenue $firstName. Votre compte est en attente d\'approbation.';
  }

  @override
  String get registerLogInButton => 'Se connecter';

  @override
  String registerSuccessWelcomePrefix(String firstName) {
    return 'Bienvenue $firstName. ';
  }

  @override
  String get registerSuccessCoachBadgeNote =>
      'Vous pouvez maintenant vous connecter. Votre badge vérifié Sirvya est en cours de vérification, ce qui peut prendre jusqu\'à 48 heures.';

  @override
  String get registerSuccessAdvisorPendingNote =>
      'Votre compte est en attente d\'approbation.';

  @override
  String get registerSuccessClientNote =>
      'Vous pouvez maintenant vous connecter.';

  @override
  String get registerStep1Label => 'ÉTAPE 1 / 5';

  @override
  String get registerStep2Label => 'ÉTAPE 2 / 5';

  @override
  String get registerStep3Label => 'ÉTAPE 3 / 5';

  @override
  String get registerStep4Label => 'ÉTAPE 4 / 5';

  @override
  String get registerStep5Label => 'ÉTAPE 5 / 5';

  @override
  String get registerStep1Title => 'Quel est\nvotre rôle ?';

  @override
  String get registerStep2Title => 'Qui êtes-vous ?';

  @override
  String get registerStep3Title => 'Sécurisez\nvotre compte';

  @override
  String get registerStep4Title => 'Conditions et\npréférences';

  @override
  String get registerStep5Title => 'Vérifiez votre\ncode par e-mail';

  @override
  String get registerStep1Sub => 'Choisissez comment vous utiliserez SIRVYA.';

  @override
  String get registerStep2Sub => 'Dites-nous comment vous appeler.';

  @override
  String get registerStep3Sub => 'Créez un mot de passe robuste.';

  @override
  String get registerStep4Sub =>
      'Personnalisez et acceptez les conditions légales.';

  @override
  String get registerStep5Sub =>
      'Saisissez le code à 6 chiffres envoyé à votre adresse e-mail.';

  @override
  String get registerOtpLabel => 'Code OTP à 6 chiffres';

  @override
  String get registerOtpHint => '123456';

  @override
  String registerOtpSentTo(String email) {
    return 'Code envoyé à $email via noreply@devunivers.com';
  }

  @override
  String get registerOtpResend => 'Renvoyer le code';

  @override
  String get registerRoleClientLabel => 'Client';

  @override
  String get registerRoleClientDesc =>
      'Trouvez un coach et réservez des séances.';

  @override
  String get registerRoleCoachLabel => 'Coach';

  @override
  String get registerRoleCoachDesc =>
      'Gérez vos clients et développez votre activité.';

  @override
  String get registerInviterCodeLabel => 'Code de parrainage (facultatif)';

  @override
  String get registerInviterCodeHint =>
      'Saisissez le code d\'invitation de votre coach';

  @override
  String get registerOr => 'OU';

  @override
  String get registerSelectRoleFirst => 'SÉLECTIONNEZ D\'ABORD UN RÔLE';

  @override
  String get registerContinueGoogle => 'CONTINUER AVEC GOOGLE';

  @override
  String get registerContinueApple => 'CONTINUER AVEC APPLE';

  @override
  String get registerFirstNameLabel => 'Prénom';

  @override
  String get registerFirstNameHint => 'Anas';

  @override
  String get registerLastNameLabel => 'Nom';

  @override
  String get registerLastNameHint => 'Benali';

  @override
  String get registerEmailLabel => 'Adresse e-mail';

  @override
  String get registerEmailHint => 'vous@email.ma';

  @override
  String get registerHeightLabel => 'Taille (cm)';

  @override
  String get registerHeightHint => '175';

  @override
  String get registerWeightLabel => 'Poids (kg)';

  @override
  String get registerWeightHint => '70';

  @override
  String get registerNutritionGoalTitle =>
      'Votre objectif nutritionnel (facultatif)';

  @override
  String get registerNutritionGoalBalanced =>
      'Adopter des habitudes équilibrées';

  @override
  String get registerNutritionGoalLose => 'Perdre du poids progressivement';

  @override
  String get registerNutritionGoalGain => 'Prendre du poids progressivement';

  @override
  String get registerNutritionGoalMaintain => 'Maintenir mon poids';

  @override
  String get registerNutritionGoalPersonal => 'Objectif personnel';

  @override
  String get registerNutritionGoalSkipped =>
      'Ignoré · Vous pourrez le configurer plus tard dans votre profil';

  @override
  String get registerNutritionGoalOptional =>
      'Facultatif · Appuyez pour configurer ou ignorer pour l\'instant';

  @override
  String get registerNutritionGoalClearTooltip => 'Effacer l\'objectif';

  @override
  String get registerNutritionGoalSkip => 'Passer';

  @override
  String registerInterestsHeader(int count) {
    return 'Vos centres d\'intérêt ($count/5)';
  }

  @override
  String registerSpecialtiesHeader(int count) {
    return 'Spécialités de coaching ($count/5)';
  }

  @override
  String get registerInterestsSub =>
      'Choisissez jusqu\'à 5 centres d\'intérêt pour personnaliser vos recommandations de coachs.';

  @override
  String get registerSpecialtiesSub => 'Choisissez jusqu\'à 5 spécialités.';

  @override
  String get registerSpecialtyStrength => 'Musculation';

  @override
  String get registerSpecialtyWeightLoss => 'Perte de poids';

  @override
  String get registerSpecialtyYoga => 'Yoga';

  @override
  String get registerSpecialtyCrossFit => 'CrossFit';

  @override
  String get registerSpecialtyBoxing => 'Boxe';

  @override
  String get registerSpecialtyNutrition => 'Nutrition';

  @override
  String get registerSpecialtyPilates => 'Pilates';

  @override
  String get registerSpecialtyCardio => 'Cardio';

  @override
  String get registerSpecialtyStretching => 'Stretching';

  @override
  String get registerSpecialtyFunctional => 'Functional Training';

  @override
  String get registerPasswordLabel => 'Mot de passe';

  @override
  String get registerPasswordHint => '••••••••';

  @override
  String get registerConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get registerConfirmPasswordHint => '••••••••';

  @override
  String get registerGenderMale => 'Homme';

  @override
  String get registerGenderFemale => 'Femme';

  @override
  String get registerGenderOther => 'Autre';

  @override
  String get registerInvitationCodeLabel => 'Code d\'invitation (facultatif)';

  @override
  String get registerInvitationCodeHint => 'ex. A1B2C3D4E5F6';

  @override
  String get registerInvitationCodeHelper =>
      'Invité par un coach ? Saisissez son code pour créditer votre inscription.';

  @override
  String get registerInvitationCodeInvalid => 'Ce code n\'est pas reconnu.';

  @override
  String get registerInvitationCodeValid => 'Code coach valide';

  @override
  String get registerTermsAgreePrefix => 'J\'accepte le ';

  @override
  String get registerTermsAgreeLink =>
      'Cadre juridique et de conformité principal de Sirvya';

  @override
  String get registerTermsAgreeSuffix =>
      ' incluant les Conditions d\'utilisation, la Politique de confidentialité et les Avertissements.';

  @override
  String get registerTermsReadButton => 'Lire le cadre complet';

  @override
  String get registerTermsModalHeader => 'CADRE JURIDIQUE PRINCIPAL DE SIRVYA';

  @override
  String get registerTermsSecGeneralTitle => 'Informations générales';

  @override
  String get registerTermsSecGeneralBody =>
      'Date d\'entrée en vigueur : Novembre 2026\nVersion : 1.0.3\nEntité exploitante : DevUnivers (Maroc)\nContact : privacy@devunivers.com | support@devunivers.com\nPlateforme : Application mobile Sirvya et infrastructure associée';

  @override
  String get registerTermsSecScopeTitle =>
      'Cadre juridique et portée internationale';

  @override
  String get registerTermsSecScopeBody =>
      'Sirvya est exploitée par DevUnivers au Maroc et conçue pour une accessibilité mondiale. Ce cadre juridique complet régit votre utilisation de Sirvya dans le monde entier. Il respecte la réglementation marocaine sur la protection de la vie privée (Loi 09-08 / CNDP) et s\'aligne sur les références internationales en matière de protection des données, notamment le Règlement général sur la protection des données (RGPD) de l\'UE et les normes mondiales de protection des consommateurs.';

  @override
  String get registerTermsSecDefsTitle => 'Définitions';

  @override
  String get registerTermsSecDefsBody =>
      '• Plateforme : désigne l\'application Sirvya, son infrastructure web associée, ses services d\'IA et les systèmes fournis par DevUnivers.\n• Société : désigne DevUnivers, l\'entité juridique exploitante.\n• Utilisateur : toute personne créant un compte sur la Plateforme pour suivre sa nutrition, ses entraînements, réserver des services ou interagir avec des Coachs/Salles de sport.\n• Coach : un professionnel du fitness indépendant ou un entraîneur personnel proposant des services ou des conseils via la Plateforme.\n• Salle de sport : un établissement ou studio de fitness indépendant répertorié sur la Plateforme.';

  @override
  String get registerTermsSecTosTitle =>
      '1. Conditions générales d\'utilisation (CGU)';

  @override
  String get registerTermsSecTosBody =>
      '1.1 Acceptation des conditions\nEn accédant à Sirvya, en créant un compte ou en utilisant l\'application, vous acceptez d\'être lié par les présentes Conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, vous devez cesser toute utilisation et désinstaller l\'application.\n\n1.2 Éligibilité et conditions d\'âge\nLes utilisateurs doivent avoir au moins 18 ans (ou l\'âge de la majorité légale dans leur juridiction) pour s\'inscrire de manière indépendante. Les mineurs âgés de 13 à 17 ans ne peuvent utiliser la plateforme que sous la supervision d\'un parent/tuteur et avec un consentement vérifiable. Sirvya n\'est strictement pas destinée aux enfants de moins de 13 ans.\n\n1.3 Sécurité et intégrité du compte\nVous êtes responsable de la protection de vos identifiants. Le partage de compte, la revente, l\'extraction automatisée, l\'ingénierie inverse, l\'altération de la sécurité ou l\'exploitation commerciale non autorisée sont strictement interdits.\n\n1.4 Abonnements et conditions de la place de marché\nBien que certaines fonctionnalités principales soient actuellement fournies gratuitement ou en version bêta, Sirvya se réserve le droit d\'introduire des fonctionnalités premium facultatives, des abonnements ou des frais de transaction moyennant un préavis clair.\n\n1.5 Limitation de responsabilité\nDans toute la mesure permise par la loi applicable, DevUnivers, Sirvya et leurs affiliés ne sauraient être tenus responsables des dommages indirects, accessoires, punitifs ou consécutifs résultant de l\'utilisation de l\'application, des activités d\'entraînement, du suivi nutritionnel ou des interactions avec des tiers indépendants.\n\n1.6 Droit applicable et utilisateurs internationaux\nLes présentes Conditions sont régies et interprétées conformément aux lois du Royaume du Maroc. Si vous êtes un consommateur individuel résidant hors du Maroc (par exemple dans l\'Union européenne, au Royaume-Uni, aux États-Unis ou au sein du CCG), aucune disposition des présentes Conditions ne vous prive des protections légales impératives accordées aux consommateurs par les lois de votre pays de résidence habituelle. En cas de préoccupation, nous vous encourageons à contacter support@devunivers.com pour une résolution amiable.';

  @override
  String get registerTermsSecPrivacyTitle =>
      '2. Politique de confidentialité et protection des données';

  @override
  String get registerTermsSecPrivacyBody =>
      '2.1 Collecte et finalité des données\nNous collectons des données personnelles et de forme physique exclusivement pour fournir un suivi personnalisé, la découverte de coachs et des analyses nutritionnelles (nom, e-mail, âge, taille, poids, IMC, journaux de repas, macros, réservations et discussions).\n\n2.2 Consentement relatif aux données de santé et biométriques\nLe suivi de la nutrition, des calories, du poids corporel et des mesures d\'entraînement implique des données liées à la santé. En utilisant ces fonctionnalités facultatives, vous donnez votre consentement explicite pour que Sirvya stocke et traite ces données afin d\'afficher votre journal, de calculer vos objectifs caloriques et de suivre vos progrès.\n\n2.3 Analyse photo des repas par IA et Microsoft Azure\nL\'analyse facultative des photos de repas transmet des données d\'image anonymisées via un chiffrement TLS sécurisé à Microsoft Azure AI (GPT-4 mini) uniquement pour estimer les aliments, les portions et les macros. Les photos sont traitées de manière éphémère en mémoire et ne sont pas conservées sur les serveurs de Sirvya.\n\n2.4 Localisation et OpenStreetMap Nominatim\nLorsque l\'autorisation est accordée, la position de l\'appareil est utilisée pour détecter votre ville et afficher les coachs à proximité. Le géocodage inversé est assuré par OpenStreetMap Nominatim selon les garanties de confidentialité d\'OSM. Vos coordonnées GPS précises ne sont jamais diffusées aux autres utilisateurs.\n\n2.5 Droits internationaux des utilisateurs et RGPD\nQuel que soit votre pays de résidence, vous gardez le contrôle total sur vos données personnelles :\n• Droit d\'accès : demander une copie de vos données personnelles.\n• Droit de rectification : corriger ou mettre à jour toute information inexacte.\n• Droit à l\'effacement : demander la suppression totale de votre compte et des données associées.\n• Droit de retrait du consentement : interrompre à tout moment le suivi de santé ou de localisation.\n• Suppression dans l\'application : vous pouvez supprimer définitivement votre compte directement depuis les paramètres de votre profil.\nPour toute question relative à la confidentialité, contactez privacy@devunivers.com.';

  @override
  String get registerTermsSecHealthTitle =>
      '3. Avertissements médicaux, de santé et relatifs aux allergènes';

  @override
  String get registerTermsSecHealthBody =>
      '3.1 PAS UN PRESTATAIRE DE SOINS DE SANTÉ\nSIRVYA N\'EST NI UNE PLATEFORME MÉDICALE, NI UN DISPOSITIF MÉDICAL, NI UN PRESTATAIRE DE SOINS DE SANTÉ. Le contenu de l\'application, les estimations de l\'IA et les services des Coachs sont fournis à titre informatif uniquement et ne doivent JAMAIS remplacer un diagnostic médical qualifié ou l\'avis d\'un professionnel de santé.\n\n3.2 AVERTISSEMENT CRITIQUE SUR LES ALLERGIES\nNI SIRVYA, NI SON SCANNER D\'IMAGES PAR IA, NI SES BASES DE DONNÉES D\'INGRÉDIENTS NE DÉTECTENT OU NE VÉRIFIENT LES ALLERGÈNES (tels que les arachides, les fruits à coque, le gluten, les produits laitiers, les crustacés, le soja ou les œufs). NE vous fiez JAMAIS à Sirvya ou aux analyses photo si vous souffrez d\'allergies alimentaires, de la maladie cœliaque ou de restrictions alimentaires médicales. Vérifiez toujours les étiquettes des fabricants.\n\n3.3 Acceptation des risques physiques\nL\'exercice physique comporte des risques inhérents de blessure. Consultez un médecin agréé avant de commencer tout nouveau programme d\'entraînement ou de nutrition. Vous assumez volontairement tous les risques physiques liés aux entraînements.\n\n3.4 Services d\'urgence\nEn cas d\'urgence médicale, contactez immédiatement vos services d\'urgence locaux (tels que le 15/190 au Maroc, le 112 dans l\'UE ou le 911 aux États-Unis).';

  @override
  String get registerTermsSecOpenSourceTitle =>
      '4. Attribution Open Source et bases de données tierces';

  @override
  String get registerTermsSecOpenSourceBody =>
      'Les informations alimentaires et nutritionnelles dans Sirvya sont fournies en partie par la base de données collaborative mondiale Open Food Facts (openfoodfacts.org), mise à disposition sous licence Open Database License (ODbL 1.0) et Database Contents License (DbCL). Open Food Facts est un projet indépendant de données ouvertes et ne cautionne pas Sirvya.';

  @override
  String get registerTermsSecCoachTitle =>
      '5. Conditions applicables aux Coachs et Salles de sport (Prestataires indépendants)';

  @override
  String get registerTermsSecCoachBody =>
      '5.1 Statut d\'indépendant\nSirvya est une plateforme technologique neutre mettant en relation les utilisateurs avec des prestataires de fitness. Les Coachs et Salles de sport exercent en tant qu\'entreprises indépendantes et sont seuls responsables de leurs séances, de leurs conseils et de leurs qualifications.\n\n5.2 Tolérance zéro pour les justificatifs frauduleux\nLa falsification de certifications professionnelles ou toute fausse déclaration entraîne l\'exclusion immédiate du compte et d\'éventuelles poursuites judiciaires.';

  @override
  String get registerTermsSecCommunityTitle =>
      '6. Règles de la communauté et propriété intellectuelle';

  @override
  String get registerTermsSecCommunityBody =>
      '6.1 Standards de la communauté : tolérance zéro pour le harcèlement, les discours haineux, le spam, les contenus offensants ou la sollicitation commerciale non autorisée.\n\n6.2 Propriété intellectuelle : les éléments de marque, designs, codes et interfaces de Sirvya sont la propriété exclusive de DevUnivers. Les utilisateurs conservent la propriété de leurs contenus d\'entraînement personnels.';

  @override
  String get registerTermsSecBookingTitle =>
      '7. Politique de réservation et d\'annulation';

  @override
  String get registerTermsSecBookingBody =>
      '7.1 Engagement : des systèmes automatisés détectent et préviennent les réservations frauduleuses.\n7.2 Politiques des prestataires : les annulations de séances individuelles sont régies par la politique spécifique du Coach ou de la Salle de sport choisie lors de la réservation.';

  @override
  String get registerTermsAcceptButton => 'J\'ACCEPTE LES CONDITIONS';

  @override
  String get registerCtaContinue => 'CONTINUER';

  @override
  String get registerCtaVerifyCreate => 'VÉRIFIER ET CRÉER LE COMPTE';

  @override
  String get registerAlreadyRegistered => 'Déjà inscrit ?';

  @override
  String get registerCtaLogIn => 'SE CONNECTER';

  @override
  String get registerPasswordWeak => 'Faible';

  @override
  String get registerPasswordMedium => 'Moyen';

  @override
  String get registerPasswordGood => 'Bon';

  @override
  String get registerPasswordStrong => 'Fort';

  @override
  String registerPasswordSecurity(String strength) {
    return 'Sécurité : $strength';
  }

  @override
  String get clientForgotErrorInvalidEmail => 'Adresse e-mail invalide';

  @override
  String get clientForgotErrorOtpLength =>
      'Saisissez le code de vérification à 6 chiffres';

  @override
  String get clientForgotErrorPasswordShort =>
      'Mot de passe trop court (min. 6 caractères)';

  @override
  String get clientForgotErrorPasswordsMismatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get clientForgotErrorEmailNotFound => 'Adresse e-mail introuvable';

  @override
  String get clientForgotErrorServerUnreachable =>
      'Impossible de joindre le serveur';

  @override
  String get clientForgotErrorInvalidOtp => 'Code de vérification invalide';

  @override
  String get clientForgotErrorResetFailed =>
      'Erreur lors de la réinitialisation du mot de passe';

  @override
  String get clientForgotSuccessTitle => 'Mot de passe mis à jour';

  @override
  String get clientForgotSuccessMessage =>
      'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.';

  @override
  String get clientForgotLogInCta => 'SE CONNECTER';

  @override
  String get clientForgotStep1Label => 'ÉTAPE 1 / 3';

  @override
  String get clientForgotStep2Label => 'ÉTAPE 2 / 3';

  @override
  String get clientForgotStep3Label => 'ÉTAPE 3 / 3';

  @override
  String get clientForgotStep1Title => 'Votre\nadresse e-mail';

  @override
  String get clientForgotStep2Title => 'Code de\nvérification';

  @override
  String get clientForgotStep3Title => 'Nouveau\nmot de passe';

  @override
  String get clientForgotStep1Sub =>
      'Saisissez votre e-mail pour recevoir un code de réinitialisation.';

  @override
  String get clientForgotStep2Sub =>
      'Saisissez le code à 6 chiffres envoyé à votre adresse e-mail.';

  @override
  String get clientForgotStep3Sub =>
      'Choisissez un nouveau mot de passe sécurisé.';

  @override
  String get clientForgotEmailLabel => 'Adresse e-mail';

  @override
  String get clientForgotEmailHint => 'vous@email.ma';

  @override
  String get clientForgotOtpLabel => 'Code OTP à 6 chiffres';

  @override
  String get clientForgotOtpHint => '123456';

  @override
  String get clientForgotResendCode => 'Renvoyer le code';

  @override
  String get clientForgotNewPasswordLabel => 'Nouveau mot de passe';

  @override
  String get clientForgotNewPasswordHint => '••••••••';

  @override
  String get clientForgotConfirmPasswordLabel => 'Confirmer le mot de passe';

  @override
  String get clientForgotConfirmPasswordHint => '••••••••';

  @override
  String get clientForgotCtaSendCode => 'ENVOYER LE CODE';

  @override
  String get clientForgotCtaVerifyCode => 'VÉRIFIER LE CODE';

  @override
  String get clientForgotCtaResetPassword => 'RÉINITIALISER LE MOT DE PASSE';

  @override
  String get clientForgotRememberPassword =>
      'Vous vous souvenez de votre mot de passe ? ';

  @override
  String get clientForgotLogInLink => 'Se connecter';

  @override
  String get clientForgotPasswordWeak => 'Faible';

  @override
  String get clientForgotPasswordMedium => 'Moyen';

  @override
  String get clientForgotPasswordGood => 'Bon';

  @override
  String get clientForgotPasswordStrong => 'Fort';

  @override
  String clientForgotPasswordSecurity(String strength) {
    return 'Sécurité : $strength';
  }

  @override
  String get headerFooterNavHome => 'Accueil';

  @override
  String get headerFooterNavExplore => 'Explorer';

  @override
  String get headerFooterNavSessions => 'Séances';

  @override
  String get headerFooterNavProfile => 'Profil';

  @override
  String headerFooterHomeContent(int index) {
    return 'Contenu d\'accueil $index';
  }

  @override
  String get coachOnboardingErrorInvalidQr =>
      'Ce code QR n\'est pas une invitation coach valide.';

  @override
  String get coachOnboardingErrorInvalidCode =>
      'Ce code d\'invitation n\'est pas reconnu.';

  @override
  String get coachOnboardingErrorUploadFailed => 'L\'envoi a échoué.';

  @override
  String get coachOnboardingLogOut => 'Se déconnecter';

  @override
  String get coachOnboardingOfflineTitle =>
      'Impossible de vérifier votre compte';

  @override
  String get coachOnboardingOfflineSubtitle =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get coachOnboardingRetry => 'RÉESSAYER';

  @override
  String get coachOnboardingBadgeVerification => 'VÉRIFICATION';

  @override
  String get coachOnboardingChoicesTitle => 'Vérifiez votre\ncompte coach';

  @override
  String get coachOnboardingChoicesSubtitle =>
      'Cette étape est obligatoire pour accéder à SIRVYA en tant que coach.';

  @override
  String get coachOnboardingQrTag => 'ACCÈS INSTANTANÉ';

  @override
  String get coachOnboardingQrTitle => 'Scanner un code QR d\'invitation';

  @override
  String get coachOnboardingQrDesc =>
      'Scannez le code QR du coach qui vous a invité et accédez immédiatement à l\'application.';

  @override
  String get coachOnboardingOr => 'OU';

  @override
  String get coachOnboardingCertTag => 'VÉRIFICATION · JUSQU\'À 48H';

  @override
  String get coachOnboardingCertTitle => 'Prendre en photo votre certificat';

  @override
  String get coachOnboardingCertDesc =>
      'Notre équipe vérifie vos qualifications. Vous accédez à l\'application dès que votre demande est approuvée.';

  @override
  String get coachOnboardingPrivacyNotice =>
      'Vos documents sont uniquement utilisés pour vérifier votre identité en tant que coach.';

  @override
  String get coachOnboardingBadgePending => 'EN ATTENTE D\'EXAMEN';

  @override
  String get coachOnboardingWaitingTitle => 'En attente\nd\'approbation';

  @override
  String get coachOnboardingWaitingSubtitle =>
      'Votre certificat a été envoyé. Vous aurez accès dès que notre équipe l\'aura approuvé.';

  @override
  String get coachOnboardingStepSentTitle => 'Certificat envoyé';

  @override
  String get coachOnboardingStepSentSub => 'Nous avons bien reçu votre photo.';

  @override
  String get coachOnboardingStepReviewTitle => 'En cours d\'examen';

  @override
  String get coachOnboardingStepReviewSub => 'Généralement sous 48 heures.';

  @override
  String get coachOnboardingStepApprovedTitle => 'Approuvé';

  @override
  String get coachOnboardingStepApprovedSub =>
      'Vous bénéficiez d\'un accès complet à SIRVYA.';

  @override
  String get coachOnboardingCheckStatus => 'VÉRIFIER LE STATUT';

  @override
  String get coachOnboardingSendAnotherPhoto => 'Envoyer une autre photo';

  @override
  String get coachAboutYouErrorUploadFailed => 'L\'envoi a échoué';

  @override
  String get coachAboutYouPhotoReady =>
      'Photo prête. Enregistrez pour confirmer.';

  @override
  String coachAboutYouErrorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get coachAboutYouSelectLanguageTitle => 'Choisir une langue';

  @override
  String get coachAboutYouLanguageAlreadyAdded => 'Langue déjà ajoutée';

  @override
  String get coachAboutYouLangArabic => 'Arabe';

  @override
  String get coachAboutYouLangFrench => 'Français';

  @override
  String get coachAboutYouLangEnglish => 'Anglais';

  @override
  String get coachAboutYouLangSpanish => 'Espagnol';

  @override
  String get coachAboutYouLangTamazight => 'Tamazight';

  @override
  String get coachAboutYouLangGerman => 'Allemand';

  @override
  String get coachAboutYouLangItalian => 'Italien';

  @override
  String get coachAboutYouLangDutch => 'Néerlandais';

  @override
  String get coachAboutYouLangPortuguese => 'Portugais';

  @override
  String get coachAboutYouLangRussian => 'Russe';

  @override
  String get coachAboutYouErrorFullName => 'Veuillez saisir votre nom complet';

  @override
  String get coachAboutYouProfileUpdated => 'Profil mis à jour';

  @override
  String get coachAboutYouErrorUpdating => 'Erreur lors de la mise à jour';

  @override
  String get coachAboutYouTitle => 'À propos de vous';

  @override
  String get coachAboutYouPreview => 'Aperçu';

  @override
  String get coachAboutYouChangePhoto => 'Changer la photo';

  @override
  String get coachAboutYouFullNameLabel => 'Nom complet';

  @override
  String get coachAboutYouProfessionalTitleLabel => 'Titre professionnel';

  @override
  String get coachAboutYouBioLabel => 'À propos de moi';

  @override
  String get coachAboutYouLanguagesLabel => 'Langues';

  @override
  String get coachAboutYouAddLanguage => 'Ajouter';

  @override
  String get coachAboutYouGenderLabel => 'Genre (facultatif)';

  @override
  String get coachAboutYouGenderMale => 'Homme';

  @override
  String get coachAboutYouGenderFemale => 'Femme';

  @override
  String get coachAboutYouGenderOther => 'Autre';

  @override
  String get coachAboutYouGenderHint =>
      'Choisissez si cette information apparaît sur votre profil public.';

  @override
  String get coachAboutYouShowOnProfile => 'Afficher sur le profil';

  @override
  String get coachAboutYouInstagramDialogTitle => 'Identifiant Instagram';

  @override
  String get coachAboutYouInstagramHint => 'ex. mouad.coach';

  @override
  String get coachAboutYouCancel => 'Annuler';

  @override
  String get coachAboutYouSave => 'Enregistrer';

  @override
  String get coachAboutYouErrorAddInstagramFirst =>
      'Veuillez d\'abord ajouter votre identifiant Instagram';

  @override
  String get coachAboutYouErrorLaunchInstagram =>
      'Impossible d\'ouvrir Instagram';

  @override
  String get coachAboutYouContactTitle => 'Contact';

  @override
  String get coachAboutYouInstagramTitle => 'Instagram';

  @override
  String get coachAboutYouAddInstagram => 'Ajouter Instagram';

  @override
  String get coachAboutYouOpen => 'Ouvrir';

  @override
  String get coachAboutYouEmailPhoneManaged =>
      'L\'e-mail et le téléphone sont gérés\ndans les Paramètres du compte.';

  @override
  String get coachAboutYouAccountSettings => 'Paramètres du compte';

  @override
  String get coachAboutYouSaveChanges => 'Enregistrer';

  @override
  String get clientHomeSessionFallback => 'Séance';

  @override
  String get clientHomeUpdateFavoritesFailed =>
      'Impossible de mettre à jour les favoris';

  @override
  String clientHomeErrorCode(int statusCode) {
    return 'Erreur ($statusCode)';
  }

  @override
  String get clientHomeLoadRecommendationsFailed =>
      'Impossible de charger les recommandations. Veuillez réessayer.';

  @override
  String get clientHomeConnectFailed =>
      'Connexion impossible. Veuillez réessayer.';

  @override
  String get clientHomeServerUnreachable => 'Serveur inaccessible';

  @override
  String get clientHomeNutritionDiaryTitle => 'Votre journal nutritionnel';

  @override
  String get clientHomeNutritionDiarySubtitle =>
      'Calories, macros et chaque repas';

  @override
  String get clientHomeSectionMyFavorites => 'Mes favoris';

  @override
  String get clientHomeSectionRecommended => 'Recommandés pour vous';

  @override
  String get clientHomeSetLocationDistances =>
      'Définir votre position pour voir les distances';

  @override
  String get clientHomeSectionUpcomingSessions => 'Prochaines séances';

  @override
  String get clientHomeSectionCoachingCompanies => 'Entreprises de coaching';

  @override
  String get clientHomeHeroTitle => 'Vos\nObjectifs.\nNos Coachs.';

  @override
  String get clientHomeHeroSubtitle =>
      'Trouvez le bon coach, réservez une\nséance et commencez votre parcours.';

  @override
  String get clientHomeFindYourCoach => 'Trouver votre coach';

  @override
  String get clientHomeTagline => 'S\'ENTRAÎNER • SE CONNECTER • PROGRESSER';

  @override
  String get clientHomeSetLocation => 'Position';

  @override
  String get clientHomeActionBookSession => 'Réserver une\nséance';

  @override
  String get clientHomeActionFindCoach => 'Trouver un\ncoach';

  @override
  String get clientHomeActionScanQr => 'Scanner\nQR';

  @override
  String get clientHomeActionScanMeal => 'Sirvya IA\nScanner repas';

  @override
  String get clientHomeSeeAll => 'Tout voir';

  @override
  String get clientHomeCategoryAll => 'Tous';

  @override
  String get clientHomeNoCoachesAvailable => 'Aucun coach disponible';

  @override
  String get clientHomeRetry => 'Réessayer';

  @override
  String clientHomeSessionTodayAt(String time) {
    return 'Aujourd\'hui • $time';
  }

  @override
  String clientHomeSessionTomorrowAt(String time) {
    return 'Demain • $time';
  }

  @override
  String clientHomeSessionDateAt(String date, String time) {
    return '$date • $time';
  }

  @override
  String clientHomeWithCoach(String coachName) {
    return 'Avec $coachName';
  }

  @override
  String get clientHomeNoCompaniesAvailable => 'Aucune entreprise disponible';

  @override
  String get clientHomeNewBadge => 'Nouveau';

  @override
  String clientHomeCoachCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coachs',
      one: '1 coach',
    );
    return '$_temp0';
  }

  @override
  String get clientHomeCoachingDefault => 'Coaching';

  @override
  String get clientHomeCountryDefault => 'Maroc';

  @override
  String clientHomeCompanyReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return ' ($_temp0)';
  }

  @override
  String get clientHomeViewCoaches => 'VOIR LES COACHS';

  @override
  String get clientListLocationServicesDisabled =>
      'Les services de localisation sont désactivés.';

  @override
  String get clientListLocationPermissionDenied =>
      'Les autorisations de localisation sont refusées.';

  @override
  String get clientListLocationPermissionDeniedForever =>
      'Les autorisations de localisation sont définitivement refusées.';

  @override
  String get clientListFetchingLocation => 'Récupération de la position...';

  @override
  String clientListGetLocationFailed(String error) {
    return 'Impossible d\'obtenir la position : $error';
  }

  @override
  String clientListServerError(int statusCode) {
    return 'Erreur du serveur ($statusCode)';
  }

  @override
  String get clientListLoadRecommendationsFailed =>
      'Impossible de charger les recommandations. Veuillez réessayer.';

  @override
  String get clientListConnectFailed =>
      'Connexion impossible. Veuillez réessayer.';

  @override
  String get clientListServerUnreachable => 'Serveur inaccessible.';

  @override
  String get clientListFiltersButton => 'Filtres';

  @override
  String get clientListAllSpecialties => 'Toutes les spécialités';

  @override
  String get clientListFindACoach => 'Trouver un coach';

  @override
  String get clientListMapToggle => 'Carte';

  @override
  String get clientListListToggle => 'Liste';

  @override
  String get clientListSearchHint => 'Rechercher des coachs, spécialités...';

  @override
  String get clientListVerifiedOnly => 'Vérifiés uniquement';

  @override
  String clientListMinRatingChip(String rating) {
    return '$rating+ étoiles';
  }

  @override
  String get clientListFilterCoachesTitle => 'Filtrer les coachs';

  @override
  String get clientListDone => 'Terminé';

  @override
  String get clientListVerifiedOnlySubtitle =>
      'Afficher les coachs vérifiés par Sirvya';

  @override
  String get clientListSortByLabel => 'TRIER PAR';

  @override
  String get clientListSortRecommended => 'Recommandés pour vous';

  @override
  String get clientListSortPoints => 'Points';

  @override
  String get clientListSortAlphabetical => 'Alphabétique';

  @override
  String get clientListSortTopRated => 'Mieux notés';

  @override
  String get clientListMinRatingLabel => 'NOTE MINIMALE';

  @override
  String get clientListClear => 'Effacer';

  @override
  String get clientListAll => 'Tous';

  @override
  String get clientListCityLabel => 'VILLE';

  @override
  String get clientListLocationToBeDefined => 'À définir';

  @override
  String get clientListCompanyIndependent => 'Indépendant';

  @override
  String clientListNoCoachesInCity(String city) {
    return 'Aucun coach trouvé à $city';
  }

  @override
  String get clientListNoCoachesFound => 'Aucun coach trouvé';

  @override
  String clientListCoachesFoundCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coachs trouvés',
      one: '1 coach trouvé',
    );
    return '$_temp0';
  }

  @override
  String get clientListListViewTooltip => 'Vue liste';

  @override
  String get clientListGridViewTooltip => 'Vue grille';

  @override
  String get clientListSortAction => 'Trier';

  @override
  String clientListNoCompaniesInCity(String city) {
    return 'Aucune entreprise trouvée à $city';
  }

  @override
  String get clientListNoCompaniesFound => 'Aucune entreprise trouvée';

  @override
  String get clientListRetry => 'Réessayer';

  @override
  String get clientListReset => 'Réinitialiser';

  @override
  String get clientListPremiumBadge => 'PREMIUM';

  @override
  String get clientListNewBadge => 'Nouveau';

  @override
  String get clientListAvailableToday => 'Disponible aujourd\'hui';

  @override
  String get clientListPriceFrom => 'À partir de';

  @override
  String clientListPriceCurrency(int price) {
    return '$price MAD';
  }

  @override
  String get clientListPriceLabel => 'Tarif';

  @override
  String get clientListPriceOnRequest => 'Tarif sur demande';

  @override
  String get clientListViewAndBook => 'Voir et réserver';

  @override
  String get clientListCodeCopied => 'Code copié';

  @override
  String get clientListNumberCopied => 'Numéro copié';

  @override
  String get clientListViewCoachesBadge => 'Voir les coachs';

  @override
  String get clientListViewProfile => 'VOIR LE PROFIL';

  @override
  String clientCoachFavoritesServerError(int statusCode) {
    return 'Erreur du serveur ($statusCode)';
  }

  @override
  String get clientCoachFavoritesServerUnreachable => 'Serveur inaccessible';

  @override
  String get clientCoachFavoritesUpdateFailed =>
      'Impossible de mettre à jour les favoris';

  @override
  String get clientCoachFavoritesLocationToBeDefined => 'À définir';

  @override
  String get clientCoachFavoritesCompanyIndependent => 'Indépendant';

  @override
  String get clientCoachFavoritesTitle => 'Mes favoris';

  @override
  String get clientCoachFavoritesLoading => 'Chargement…';

  @override
  String get clientCoachFavoritesEmptySubtitle =>
      'Les coachs que vous aimez apparaîtront ici';

  @override
  String clientCoachFavoritesSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coachs enregistrés',
      one: '1 coach enregistré',
    );
    return '$_temp0';
  }

  @override
  String get clientCoachFavoritesSearchHint =>
      'Rechercher vos coachs favoris...';

  @override
  String get clientCoachFavoritesRetry => 'Réessayer';

  @override
  String get clientCoachFavoritesEmptyTitle =>
      'Aucun coach favori pour le moment';

  @override
  String get clientCoachFavoritesEmptyMessage =>
      'Appuyez sur le cœur d\'un coach pour l\'enregistrer ici.';

  @override
  String get clientCoachFavoritesFindACoach => 'Trouver un coach';

  @override
  String get clientCoachFavoritesNoResults =>
      'Aucun coach ne correspond à votre recherche';

  @override
  String get clientCoachFavoritesReset => 'Réinitialiser';

  @override
  String get clientCoachFavoritesNewBadge => 'Nouveau';

  @override
  String get clientCoachFavoritesViewProfile => 'VOIR LE PROFIL';

  @override
  String get clientCoachReviewsLoadFailed =>
      'Impossible de charger les avis. Tirez vers le bas pour réessayer.';

  @override
  String get clientCoachReviewsMyFeedbackTitle => 'Mes retours';

  @override
  String get clientCoachReviewsTitle => 'Avis et notes';

  @override
  String clientCoachReviewsAllCount(int count) {
    return 'Tous les avis ($count)';
  }

  @override
  String clientCoachReviewsStarCount(int stars, int count) {
    return 'Avis $stars étoiles ($count)';
  }

  @override
  String get clientCoachReviewsClearFilter => 'Effacer le filtre';

  @override
  String clientCoachReviewsTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$_temp0';
  }

  @override
  String clientCoachReviewsFilterAll(int count) {
    return 'Tous ($count)';
  }

  @override
  String clientCoachReviewsEmptyStarFilter(int stars) {
    return 'Aucun avis avec $stars étoiles pour le moment';
  }

  @override
  String get clientCoachReviewsEmptyCoachView =>
      'Les retours de vos clients apparaîtront ici';

  @override
  String get clientCoachReviewsEmptyClientView => 'Aucun avis trouvé';

  @override
  String get clientCoachReviewsMyReviewBadge => 'Mon avis';

  @override
  String get clientCompanyDetailNotFound => 'Conseiller introuvable';

  @override
  String clientCompanyDetailLoadError(int statusCode) {
    return 'Erreur lors du chargement ($statusCode)';
  }

  @override
  String get clientCompanyDetailVerifiedBadge => 'VÉRIFIÉ';

  @override
  String get clientCompanyDetailStatCoaches => 'Coachs';

  @override
  String get clientCompanyDetailStatInvitations => 'Invitations';

  @override
  String get clientCompanyDetailStatPoints => 'Points';

  @override
  String clientCompanyDetailTabCoaches(int count) {
    return 'COACHS ($count)';
  }

  @override
  String get clientCompanyDetailTabAbout => 'À PROPOS';

  @override
  String clientCompanyDetailTabGallery(int count) {
    return 'GALERIE ($count)';
  }

  @override
  String get clientCompanyDetailTabLocation => 'LOCALISATION';

  @override
  String get clientCompanyDetailNoCoaches =>
      'Aucun coach rattaché pour le moment';

  @override
  String get clientCompanyDetailCertifiedCoach => 'Coach certifié';

  @override
  String get clientCompanyDetailSectionProfile => 'PROFIL';

  @override
  String get clientCompanyDetailFullName => 'Nom complet';

  @override
  String get clientCompanyDetailEmail => 'E-mail';

  @override
  String get clientCompanyDetailSpecialty => 'Spécialité';

  @override
  String get clientCompanyDetailCity => 'Ville';

  @override
  String get clientCompanyDetailGymName => 'Nom de la salle';

  @override
  String get clientCompanyDetailAddress => 'Adresse';

  @override
  String get clientCompanyDetailSectionStatistics => 'STATISTIQUES';

  @override
  String get clientCompanyDetailStatTeamCoaches => 'Coachs dans l\'équipe';

  @override
  String get clientCompanyDetailStatTotalInvitations => 'Total des invitations';

  @override
  String get clientCompanyDetailStatTotalPoints => 'Total des points';

  @override
  String get clientCompanyDetailNoGalleryImages =>
      'Aucune image de la salle pour le moment';

  @override
  String get clientCompanyDetailSectionAddress => 'ADRESSE';

  @override
  String get clientCompanyDetailAddressNotProvided => 'Adresse non renseignée';

  @override
  String get clientCompanyDetailSectionMap => 'CARTE';

  @override
  String get clientCompanyDetailLocationNotAvailable =>
      'Localisation non disponible';

  @override
  String get clientCompanyDetailGymDefault => 'Salle';

  @override
  String get clientCompanyDetailOpenMap => 'OUVRIR';

  @override
  String get clientCompanyDetailLoadingErrorTitle => 'Erreur de chargement';

  @override
  String get clientCompanyDetailRetry => 'RÉESSAYER';

  @override
  String get clientCompanyDetailViewProfile => 'VOIR LE PROFIL';

  @override
  String get clientCompanyDetailCoachDefault => 'Coach';

  @override
  String get clientCompanyDetailAnywhere => 'Partout';

  @override
  String get clientCompanyDetailNewBadge => 'Nouveau';

  @override
  String clientCompanyDetailReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$_temp0';
  }

  @override
  String clientCompanyDetailInvitationsShort(int count) {
    return '$count inv.';
  }

  @override
  String clientCompanyDetailPointsShort(int count) {
    return '$count pts';
  }

  @override
  String clientProfilServerError(int statusCode) {
    return 'Erreur du serveur ($statusCode)';
  }

  @override
  String get clientProfilCheckConnection =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get clientProfilLoadFailed =>
      'Impossible de charger votre profil. Veuillez réessayer.';

  @override
  String get clientProfilWeightLoadFailed =>
      'Impossible de charger vos derniers relevés. Appuyez sur Actualiser l\'historique pour réessayer.';

  @override
  String get clientProfilWeightSaveFailed =>
      'Impossible d\'enregistrer le poids.';

  @override
  String get clientProfilWeightSaved => 'Poids enregistré ✓';

  @override
  String get clientProfilPhotoSaveFailed =>
      'Impossible d\'enregistrer votre photo. Veuillez réessayer.';

  @override
  String get clientProfilPhotoUpdated => 'Photo de profil mise à jour ✓';

  @override
  String get clientProfilUploadError => 'Erreur de téléversement';

  @override
  String clientProfilGenericError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get clientProfilNameRequired =>
      'Veuillez renseigner votre prénom et votre nom.';

  @override
  String get clientProfilInvalidHeight =>
      'Veuillez saisir une taille valide en centimètres.';

  @override
  String get clientProfilSaveFailed => 'Erreur lors de l\'enregistrement.';

  @override
  String get clientProfilServerUnreachable =>
      'Impossible de joindre le serveur.';

  @override
  String get clientProfilDeleteBlockedDefault =>
      'Impossible de supprimer le compte pour le moment.';

  @override
  String get clientProfilSendCodeFailed => 'Échec de l\'envoi du code.';

  @override
  String get clientProfilEnterFullCode =>
      'Veuillez saisir le code complet à 6 chiffres.';

  @override
  String get clientProfilVerificationFailed => 'La vérification a échoué.';

  @override
  String get clientProfilDeleteAccountTitle => 'Supprimer le compte';

  @override
  String get clientProfilDeletePermanentSubtitle =>
      'Cette action est définitive';

  @override
  String get clientProfilDeleteWhatWillBeDeleted => 'Ce qui sera supprimé :';

  @override
  String get clientProfilDeleteItemProfile =>
      'Votre profil et vos informations personnelles';

  @override
  String get clientProfilDeleteItemSessions =>
      'Toutes vos séances et l\'historique de vos réservations';

  @override
  String get clientProfilDeleteItemMessages => 'Vos messages et conversations';

  @override
  String get clientProfilDeleteItemWeight =>
      'Votre suivi de poids et vos données sportives';

  @override
  String get clientProfilDeleteUnderstandCheckbox =>
      'Je comprends que cette action est irréversible et que toutes mes données seront définitivement supprimées.';

  @override
  String get clientProfilCancel => 'Annuler';

  @override
  String get clientProfilSendCode => 'ENVOYER LE CODE';

  @override
  String get clientProfilVerifyIdentityTitle => 'Vérifiez votre identité';

  @override
  String get clientProfilVerifyCheckEmailSubtitle =>
      'Consultez vos e-mails pour obtenir le code';

  @override
  String get clientProfilVerifyInstructions =>
      'Saisissez le code à 6 chiffres envoyé à votre adresse e-mail pour confirmer la suppression du compte.';

  @override
  String clientProfilCodeExpiresIn(String minutes, String seconds) {
    return 'Le code expire dans $minutes:$seconds';
  }

  @override
  String get clientProfilCodeExpired => 'Code expiré';

  @override
  String get clientProfilResendCode => 'Renvoyer le code';

  @override
  String get clientProfilBack => 'Retour';

  @override
  String get clientProfilDeleteAccountBtn => 'SUPPRIMER LE COMPTE';

  @override
  String get clientProfilGenderMale => 'Homme';

  @override
  String get clientProfilGenderFemale => 'Femme';

  @override
  String get clientProfilGenderOther => 'Autre';

  @override
  String get clientProfilPasswordUpdated => 'Mot de passe mis à jour ✓';

  @override
  String get clientProfilLoadingProfile => 'Chargement du profil...';

  @override
  String get clientProfilRetry => 'Réessayer';

  @override
  String get clientProfilSaving => 'Enregistrement…';

  @override
  String get clientProfilSaveChanges => 'Enregistrer';

  @override
  String get clientProfilHeaderTitle => 'Mon profil';

  @override
  String get clientProfilHeaderSavedSubtitle =>
      'Vos modifications sont enregistrées.';

  @override
  String get clientProfilHeaderDefaultSubtitle =>
      'Un peu plus vous. Un parcours plus fort.';

  @override
  String get clientProfilCancelEditingTooltip => 'Annuler les modifications';

  @override
  String get clientProfilEditProfileTooltip => 'Modifier le profil';

  @override
  String get clientProfilStatSessions => 'Séances';

  @override
  String get clientProfilStatCurrentWeight => 'Poids actuel';

  @override
  String clientProfilWeightValueKg(String weight) {
    return '$weight kg';
  }

  @override
  String get clientProfilStatHeight => 'Taille';

  @override
  String clientProfilHeightValueCm(String height) {
    return '$height cm';
  }

  @override
  String get clientProfilTabMyDetails => 'Mes infos';

  @override
  String get clientProfilTabMyProgress => 'Mes progrès';

  @override
  String get clientProfilTabNutrition => 'Nutrition';

  @override
  String get clientProfilEditInstructions =>
      'Effectuez vos modifications ci-dessous, puis appuyez sur Enregistrer les modifications.';

  @override
  String get clientProfilGroupAboutTitle => 'À propos de vous';

  @override
  String get clientProfilGroupAboutSubtitle =>
      'Les détails qui font de cet espace le vôtre.';

  @override
  String get clientProfilFirstName => 'Prénom';

  @override
  String get clientProfilLastName => 'Nom';

  @override
  String get clientProfilHeightCm => 'Taille (cm)';

  @override
  String get clientProfilGroupInterestsTitle =>
      'Vos centres d\'intérêt sportifs';

  @override
  String get clientProfilGroupInterestsSubtitle =>
      'Choisissez jusqu\'à 5 activités que vous aimez. Nous les utiliserons pour vous recommander des coachs.';

  @override
  String get clientProfilGroupAccountTitle => 'Compte et localisation';

  @override
  String get clientProfilGroupAccountSubtitle =>
      'Gardez vos coordonnées à jour.';

  @override
  String get clientProfilEmailAddress => 'Adresse e-mail';

  @override
  String get clientProfilAddEmail => 'Ajouter votre e-mail';

  @override
  String get clientProfilPhoneNumber => 'Numéro de téléphone';

  @override
  String get clientProfilAddPhone => 'Ajouter votre numéro de téléphone';

  @override
  String get clientProfilMyLocation => 'Ma localisation';

  @override
  String get clientProfilSetCity => 'Définir votre ville';

  @override
  String get clientProfilGroupSirvyaTitle => 'Votre espace Sirvya';

  @override
  String get clientProfilGroupSirvyaSubtitle =>
      'Vos favoris, vos préférences, votre tranquillité d\'esprit.';

  @override
  String get clientProfilFavoriteCoaches => 'Coachs favoris';

  @override
  String get clientProfilFavoriteCoachesSubtitle =>
      'Gardez vos favoris à portée de main';

  @override
  String get clientProfilNotifications => 'Notifications';

  @override
  String get clientProfilNotificationsSubtitle =>
      'Actualités concernant votre activité';

  @override
  String get clientProfilPasswordSecurity => 'Mot de passe et sécurité';

  @override
  String get clientProfilPasswordSecuritySubtitle => 'Gérer votre mot de passe';

  @override
  String get clientProfilBlockedAccounts => 'Comptes bloqués';

  @override
  String get clientProfilBlockedAccountsSubtitle =>
      'Gérer qui peut vous contacter';

  @override
  String get clientProfilLogOut => 'Se déconnecter';

  @override
  String get clientProfilDeleteMyAccount => 'Supprimer mon compte';

  @override
  String get clientProfilChooseInterests => 'Choisir vos centres d\'intérêt';

  @override
  String get clientProfilInterestsLoadFailed =>
      'Impossible de charger les centres d\'intérêt. Réessayez pour choisir dans le catalogue.';

  @override
  String get clientProfilTryAgain => 'Réessayer';

  @override
  String get clientProfilMaxInterests =>
      'Choisissez jusqu\'à 5 centres d\'intérêt.';

  @override
  String get clientProfilGender => 'Genre';

  @override
  String get clientProfilNotAddedYet => 'Non renseigné';

  @override
  String get clientBookingHomeVisitLocation =>
      'Séance à domicile — convenez de l\'adresse avec le coach par message';

  @override
  String get clientBookingDefaultLocation =>
      'Lieu à définir avec le coach par message';

  @override
  String clientBookingSessionLabel(int number) {
    return 'Séance $number';
  }

  @override
  String get clientBookingLeadTimeError =>
      'Veuillez choisir une séance prévue dans plus d\'une heure.';

  @override
  String clientBookingMultipleBookedSuccess(int count) {
    return 'Les $count séances ont été réservées avec succès !';
  }

  @override
  String get clientBookingSingleBookedSuccess =>
      'Demande de réservation envoyée avec succès !';

  @override
  String clientBookingErrorCode(int code) {
    return 'Erreur ($code)';
  }

  @override
  String get clientBookingServerUnreachable =>
      'Impossible de joindre le serveur.';

  @override
  String get clientBookingChoosePackageTitle => 'Choisir un forfait';

  @override
  String get clientBookingSelectPackageHeading => 'Sélectionner un forfait';

  @override
  String get clientBookingSelectPackageSubtitle =>
      'Choisissez le forfait qui vous convient le mieux ou réservez sans forfait.';

  @override
  String get clientBookingContinueToBooking => 'Continuer vers la réservation';

  @override
  String clientBookingPackageSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '1 séance',
    );
    return '$_temp0';
  }

  @override
  String clientBookingPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String get clientBookingPriceToDiscuss => 'Tarif à convenir';

  @override
  String get clientBookingBookWithoutPackage => 'Réserver sans forfait';

  @override
  String get clientBookingBookWithoutPackageSub =>
      'Séance unique — tarif à convenir avec le coach';

  @override
  String clientBookingBannerPackagePrice(String name, int price) {
    return '$name · $price MAD';
  }

  @override
  String clientBookingBannerPackageRequest(String name) {
    return '$name · Tarif sur demande';
  }

  @override
  String get clientBookingNoPackageSelected => 'Aucun forfait sélectionné';

  @override
  String get clientBookingPackageSessionsTitle => 'Séances du forfait';

  @override
  String clientBookingScheduledProgress(int completed, int total) {
    return '$completed sur $total planifiées';
  }

  @override
  String clientBookingSelectDatesWithPrice(int price) {
    return 'Sélectionnez une date et une heure pour chaque séance ($price MAD / séance) :';
  }

  @override
  String clientBookingSelectDatesNoPrice(int total) {
    return 'Sélectionnez une date et une heure pour chacune des $total séances de votre forfait :';
  }

  @override
  String clientBookingSessionWithPrice(int number, int price) {
    return 'Séance $number · $price MAD';
  }

  @override
  String get clientBookingSelectingNow => 'Sélection en cours...';

  @override
  String get clientBookingTapToSelect => 'Appuyez pour choisir';

  @override
  String get clientBookingHeaderTitle => 'Réserver une séance';

  @override
  String get clientBookingCoachFallback => 'Coach';

  @override
  String get clientBookingAnywhereFallback => 'Partout';

  @override
  String get clientBookingNewCoach => 'Nouveau';

  @override
  String clientBookingReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$_temp0';
  }

  @override
  String clientBookingPricePerSession(int price) {
    return '$price MAD/séance';
  }

  @override
  String clientBookingSessionDateHeader(int number, String month) {
    return 'Date de la séance $number · $month';
  }

  @override
  String get clientBookingWeekdayMon => 'L';

  @override
  String get clientBookingWeekdayTue => 'M';

  @override
  String get clientBookingWeekdayWed => 'M';

  @override
  String get clientBookingWeekdayThu => 'J';

  @override
  String get clientBookingWeekdayFri => 'V';

  @override
  String get clientBookingWeekdaySat => 'S';

  @override
  String get clientBookingWeekdaySun => 'D';

  @override
  String get clientBookingSessionLocationTitle => 'Lieu de la séance';

  @override
  String get clientBookingLocationHomeTitle => 'À mon domicile';

  @override
  String get clientBookingLocationHomeSubtitle =>
      'Convenez de votre adresse avec le coach par message';

  @override
  String get clientBookingLocationGymSubtitle =>
      'Salle du coach · confirmez l\'itinéraire par message';

  @override
  String get clientBookingLocationTbdTitle => 'À définir';

  @override
  String get clientBookingLocationTbdSubtitle =>
      'Convenez du lieu de rendez-vous avec votre coach par message';

  @override
  String clientBookingSessionTimeSlotTitle(int number) {
    return 'Créneau de la séance $number';
  }

  @override
  String get clientBookingTimeSlotsTitle => 'Créneaux horaires';

  @override
  String clientBookingAvailableSlotsCount(int count) {
    return '$count disponible(s)';
  }

  @override
  String get clientBookingSlotsFull => 'Complet';

  @override
  String clientBookingDateForSession(String date, int number) {
    return '$date · pour la séance $number';
  }

  @override
  String get clientBookingSlotSelected => '✓ Sélectionné';

  @override
  String get clientBookingSlotDuration => '1h';

  @override
  String get clientBookingSlotBlocked => 'Indisponible';

  @override
  String get clientBookingSlotBooked => 'Réservé';

  @override
  String get clientBookingLegendFree => 'Libre';

  @override
  String get clientBookingLegendUnavailable => 'Indisponible';

  @override
  String clientBookingConfirmAllSessions(int total) {
    return 'CONFIRMER LES $total SÉANCES';
  }

  @override
  String clientBookingSelectAllSessions(int completed, int total) {
    return 'CHOISIR TOUTES LES SÉANCES ($completed/$total CHOISIES)';
  }

  @override
  String clientBookingConfirmWithTime(String time) {
    return 'CONFIRMER · $time';
  }

  @override
  String get clientBookingChooseASlot => 'CHOISIR UN CRÉNEAU';

  @override
  String clientBookingSelectDateAndTimePrompt(int number) {
    return 'Veuillez choisir une date et une heure pour la séance $number';
  }

  @override
  String get clientBookingLocationYourGym => 'Votre salle de sport';

  @override
  String get clientBookingConfirmDialogTitle => 'Confirmer la réservation';

  @override
  String get clientBookingNotYetRated => 'Pas encore noté';

  @override
  String get clientBookingLabelDate => 'Date';

  @override
  String get clientBookingLabelTime => 'Heure';

  @override
  String clientBookingScheduledSessionsCount(int count) {
    return 'Séances planifiées ($count)';
  }

  @override
  String clientBookingSessionDateAtTime(String date, String time) {
    return '$date à $time';
  }

  @override
  String get clientBookingNotScheduledYet => 'Pas encore planifiée';

  @override
  String get clientBookingLabelLocation => 'Lieu';

  @override
  String get clientBookingLabelPackage => 'Forfait';

  @override
  String get clientBookingLabelTotalPrice => 'Prix total';

  @override
  String clientBookingTotalPriceMulti(int total, int perSession) {
    return '$total MAD ($perSession MAD / séance)';
  }

  @override
  String clientBookingTotalPriceSingle(int total) {
    return '$total MAD / séance';
  }

  @override
  String get clientBookingBtnCancel => 'ANNULER';

  @override
  String get clientBookingBtnConfirm => 'CONFIRMER';

  @override
  String get clientCoachDetailRemovedFavorite => 'Retiré des favoris';

  @override
  String get clientCoachDetailAddedFavorite => 'Ajouté aux favoris ✓';

  @override
  String get clientCoachDetailFavoriteUpdateFailed =>
      'Échec de la mise à jour des favoris';

  @override
  String get clientCoachDetailConnectionFailed => 'Échec de la connexion';

  @override
  String clientCoachDetailErrorCode(int code) {
    return 'Erreur $code';
  }

  @override
  String get clientCoachDetailServerUnreachable =>
      'Impossible de joindre le serveur.';

  @override
  String get clientCoachDetailSelectRatingFirst =>
      'Veuillez d\'abord sélectionner une note';

  @override
  String get clientCoachDetailReviewSaved => 'Avis enregistré ✓';

  @override
  String get clientCoachDetailServerError => 'Erreur du serveur';

  @override
  String get clientCoachDetailInvitationSent => 'Invitation envoyée au coach ✓';

  @override
  String get clientCoachDetailInvitationAlreadySent =>
      'Invitation déjà envoyée';

  @override
  String get clientCoachDetailLoginToMessage =>
      'Veuillez vous connecter pour envoyer un message au coach';

  @override
  String get clientCoachDetailConversationStartFailed =>
      'Impossible de démarrer la conversation. Veuillez réessayer.';

  @override
  String get clientCoachDetailReportReasonSpam => 'Spam';

  @override
  String get clientCoachDetailReportReasonHarassment => 'Harcèlement';

  @override
  String get clientCoachDetailReportReasonInappropriate =>
      'Contenu inapproprié';

  @override
  String get clientCoachDetailReportReasonFraud => 'Fraude / Arnaque';

  @override
  String get clientCoachDetailReportReasonOther => 'Autre';

  @override
  String clientCoachDetailReportTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String get clientCoachDetailReportPrompt =>
      'Pourquoi signalez-vous cet utilisateur ? Nous prenons ces signalements très au sérieux.';

  @override
  String get clientCoachDetailCancel => 'Annuler';

  @override
  String get clientCoachDetailSubmit => 'Envoyer';

  @override
  String get clientCoachDetailReportSubmitted =>
      'Signalement envoyé avec succès.';

  @override
  String get clientCoachDetailReportFailed =>
      'Échec de l\'envoi du signalement';

  @override
  String get clientCoachDetailNetworkError => 'Erreur réseau';

  @override
  String clientCoachDetailBlockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get clientCoachDetailBlockMessage =>
      'Cet utilisateur ne pourra plus trouver votre profil ni vous envoyer de messages. Il ne sera pas informé de ce blocage.';

  @override
  String get clientCoachDetailBlockConfirm => 'Bloquer';

  @override
  String get clientCoachDetailUserBlocked => 'Utilisateur bloqué.';

  @override
  String get clientCoachDetailBlockFailed =>
      'Échec du blocage de l\'utilisateur';

  @override
  String get clientCoachDetailQrTitle => 'Code QR du coach';

  @override
  String get clientCoachDetailCertificationsTitle => 'Certifications';

  @override
  String get clientCoachDetailVerifiedBySirvya => 'Vérifié par Sirvya';

  @override
  String get clientCoachDetailSelfReported => 'Déclaré par le coach';

  @override
  String get clientCoachDetailCoachingPackagesTitle => 'Forfaits de coaching';

  @override
  String get clientCoachDetailNoPackagesAvailable =>
      'Aucun forfait disponible pour ce coach.';

  @override
  String clientCoachDetailPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String clientCoachDetailPackageSessionInfo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances · 60 min chacune',
      one: '1 séance · 60 min',
    );
    return '$_temp0';
  }

  @override
  String get clientCoachDetailChooseAndBook => 'Réserver';

  @override
  String get clientCoachDetailSeeAll => 'Tout voir >';

  @override
  String get clientCoachDetailAgreeOnPriceNote =>
      'Convenez du tarif avant confirmation.';

  @override
  String get clientCoachDetailOnRequest => 'Sur demande';

  @override
  String get clientCoachDetailBookChip => 'Réserver >';

  @override
  String get clientCoachDetailAvailableToday => 'Disponible aujourd\'hui';

  @override
  String get clientCoachDetailReportCoachMenu => 'Signaler le coach';

  @override
  String get clientCoachDetailBlockCoachMenu => 'Bloquer le coach';

  @override
  String get clientCoachDetailStatRating => 'Note';

  @override
  String get clientCoachDetailStatReviews => 'Avis';

  @override
  String get clientCoachDetailStatClients => 'Clients';

  @override
  String clientCoachDetailPriceFrom(String price) {
    return 'À partir de $price MAD';
  }

  @override
  String get clientCoachDetailPriceOnRequest => 'Tarif sur demande';

  @override
  String clientCoachDetailSessionRatesFrom(String price) {
    return 'Tarifs des séances à partir de $price MAD';
  }

  @override
  String get clientCoachDetailContactForRates =>
      'Contactez le coach pour connaître les tarifs';

  @override
  String get clientCoachDetailMessageBtn => 'Message';

  @override
  String get clientCoachDetailRequestBookingBtn => 'Réserver';

  @override
  String get clientCoachDetailSpecialtiesTitle => 'Spécialités';

  @override
  String get clientCoachDetailAboutTitle => 'À propos';

  @override
  String get clientCoachDetailGalleryTitle => 'Galerie de coaching';

  @override
  String clientCoachDetailViewAllCount(int count) {
    return 'Tout voir ($count)';
  }

  @override
  String get clientCoachDetailCoachingFallback => 'Coaching';

  @override
  String get clientCoachDetailAvailabilityTitle => 'Disponibilités';

  @override
  String get clientCoachDetailNoSlotsAvailable => 'Aucun créneau disponible';

  @override
  String get clientCoachDetailAssociatedGymTitle => 'Salle de sport associée';

  @override
  String get clientCoachDetailPracticalInfoTitle => 'Informations pratiques';

  @override
  String get clientCoachDetailCityDefault => 'Casablanca';

  @override
  String get clientCoachDetailQrRowLabel => 'Code QR du coach';

  @override
  String get clientCoachDetailTapToEnlarge => 'Appuyez pour agrandir';

  @override
  String get clientCoachDetailClientReviewsTitle => 'Avis des clients';

  @override
  String clientCoachDetailRatingSummary(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count avis',
      one: '1 avis',
    );
    return '$rating · $_temp0 >';
  }

  @override
  String get clientCoachDetailEditMyReview => 'Modifier mon avis';

  @override
  String get clientCoachDetailLeaveAReview => 'Laisser un avis';

  @override
  String clientCoachDetailViewAllReviewsBtn(int count) {
    return 'Voir les $count avis';
  }

  @override
  String get clientCoachDetailYourRatingLabel => 'Votre note';

  @override
  String get clientCoachDetailCommentOptionalLabel =>
      'Commentaire (facultatif)';

  @override
  String get clientCoachDetailReviewHint =>
      'Partagez votre expérience avec ce coach…';

  @override
  String get clientCoachDetailUpdateReviewBtn => 'Mettre à jour l\'avis';

  @override
  String get clientCoachDetailPublishReviewBtn => 'Publier l\'avis';

  @override
  String get clientCoachDetailMyReviewBadge => 'Mon avis';

  @override
  String get clientCoachDetailNoReviewsYet => 'Aucun avis pour le moment';

  @override
  String get clientCoachDetailBeFirstToReview =>
      'Soyez le premier à partager votre expérience';

  @override
  String get clientCoachDetailRetry => 'Réessayer';

  @override
  String clientSessionsServerError(int code) {
    return 'Erreur du serveur ($code)';
  }

  @override
  String get clientSessionsCheckConnectionError =>
      'Vérifiez votre connexion et réessayez.';

  @override
  String get clientSessionsLoadError =>
      'Impossible de charger vos séances. Veuillez réessayer.';

  @override
  String get clientSessionsRefreshTooltip => 'Actualiser les séances';

  @override
  String clientSessionsCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terminées',
      one: '1 terminée',
    );
    return '$_temp0';
  }

  @override
  String get clientSessionsTitle => 'Mes séances';

  @override
  String get clientSessionsSubtitle => 'Gérez vos rendez-vous de coaching.';

  @override
  String clientSessionsTabUpcoming(int count) {
    return 'À venir ($count)';
  }

  @override
  String clientSessionsTabPast(int count) {
    return 'Passées ($count)';
  }

  @override
  String get clientSessionsTryAgain => 'Réessayer';

  @override
  String get clientSessionsEmptyUpcoming => 'Aucune séance à venir.';

  @override
  String get clientSessionsEmptyPast => 'Aucune séance passée.';

  @override
  String get clientSessionsConfirmedWhenAccepted =>
      'Votre séance est confirmée dès que le coach l\'accepte.';

  @override
  String get clientSessionsHelpTitle => 'Besoin d\'aide pour une réservation ?';

  @override
  String get clientSessionsHelpSubtitle =>
      'Contactez-nous, nous serons ravis de vous aider.';

  @override
  String get clientSessionsContactSupport => 'Contacter le support';

  @override
  String get clientSessionsFilterAll => 'Toutes';

  @override
  String get clientSessionsFilterCompleted => 'Terminées';

  @override
  String get clientSessionsFilterCancelled => 'Annulées';

  @override
  String get clientSessionsCancelDialogTitle => 'Annuler la séance';

  @override
  String get clientSessionsCancelDialogMessage =>
      'Voulez-vous vraiment annuler cette réservation ?';

  @override
  String get clientSessionsCancelDialogNo => 'NON';

  @override
  String get clientSessionsCancelDialogYes => 'OUI, ANNULER';

  @override
  String get clientSessionsStatusCompleted => 'Terminée';

  @override
  String get clientSessionsStatusPending => 'En attente';

  @override
  String get clientSessionsStatusExpired => 'Expirée';

  @override
  String get clientSessionsStatusPriceDeclined => 'Tarif refusé';

  @override
  String get clientSessionsStatusCancelled => 'Annulée';

  @override
  String get clientSessionsPriceOfferReady =>
      'Offre de tarif reçue — ouvrez les détails pour valider.';

  @override
  String get clientSessionsAwaitingPrice => 'En attente du tarif du coach.';

  @override
  String get clientSessionsAwaitingConfirmation =>
      'En attente de confirmation du coach.';

  @override
  String get clientSessionsCancelledByYou => 'Annulée par vous';

  @override
  String clientSessionsPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String clientSessionsDurationMin(int minutes) {
    return '$minutes min';
  }

  @override
  String get clientSessionsLocationTbc => 'Lieu à confirmer';

  @override
  String clientSessionsSessionPriceWithPkg(String packageName) {
    return 'Prix de la séance ($packageName)';
  }

  @override
  String get clientSessionsSessionTotal => 'Total de la séance';

  @override
  String get clientSessionsViewDetails => 'Voir les détails >';

  @override
  String get clientSessionsBookAgain => 'Réserver à nouveau >';

  @override
  String clientSessionsEditReviewRating(int rating) {
    return 'Avis : $rating/5 ';
  }

  @override
  String get clientSessionsLeaveAReview => 'Laisser un avis';

  @override
  String get clientSessionsMessageBtn => 'Message';

  @override
  String get clientSessionsCancelBooking => 'Annuler la réservation';

  @override
  String get clientSessionDetailAcceptPriceTitle =>
      'Accepter le tarif proposé ?';

  @override
  String get clientSessionDetailDeclinePriceTitle =>
      'Refuser le tarif proposé ?';

  @override
  String clientSessionDetailAcceptPriceMessage(String price) {
    return 'Accepter $price MAD et confirmer cette séance ?';
  }

  @override
  String get clientSessionDetailDeclinePriceMessage =>
      'Le refus annulera cette demande de réservation.';

  @override
  String get clientSessionDetailAcceptConfirmBtn => 'ACCEPTER ET CONFIRMER';

  @override
  String get clientSessionDetailDeclinePriceBtn => 'REFUSER LE TARIF';

  @override
  String get clientSessionDetailPriceRespondError =>
      'Impossible de répondre à la proposition de tarif.';

  @override
  String get clientSessionDetailConnectionUnavailable =>
      'Connexion indisponible. Veuillez réessayer.';

  @override
  String get clientSessionDetailPriceExpiredTitle => 'Demande de tarif expirée';

  @override
  String get clientSessionDetailApprovePriceTitle =>
      'Valider le tarif de votre séance';

  @override
  String get clientSessionDetailAwaitingPriceTitle =>
      'En attente du tarif du coach';

  @override
  String get clientSessionDetailPriceExpiredBody =>
      'Aucun tarif n\'a été convenu avant l\'échéance. Veuillez effectuer une nouvelle réservation.';

  @override
  String clientSessionDetailProposedPriceBody(String price) {
    return '$price MAD par séance. Votre acceptation confirme cette réservation.';
  }

  @override
  String get clientSessionDetailAwaitingPriceBody =>
      'Votre coach vous enverra une proposition de tarif. Vous devez l\'accepter pour confirmer la séance.';

  @override
  String clientSessionDetailPriceDeadline(String date, String time) {
    return 'Échéance : $date · $time (2 heures avant la séance)';
  }

  @override
  String get clientSessionDetailAcceptAndConfirm => 'Accepter et confirmer';

  @override
  String get clientSessionDetailDecline => 'Refuser';

  @override
  String get clientSessionDetailStatusExpired => 'EXPIRÉE';

  @override
  String get clientSessionDetailStatusPriceDeclined => 'TARIF REFUSÉ';

  @override
  String get clientSessionDetailStatusPending => 'EN ATTENTE';

  @override
  String get clientSessionDetailStatusConfirmed => 'CONFIRMÉE';

  @override
  String get clientSessionDetailStatusCancelled => 'ANNULÉE';

  @override
  String get clientSessionDetailCancelTitle => 'Annuler la séance ?';

  @override
  String get clientSessionDetailCancelMessage =>
      'Cette action est irréversible.';

  @override
  String get clientSessionDetailCancelConfirmBtn => 'ANNULER LA SÉANCE';

  @override
  String get clientSessionDetailSessionCancelledSnack => 'Séance annulée.';

  @override
  String get clientSessionDetailCancelErrorSnack =>
      'Erreur lors de l\'annulation.';

  @override
  String get clientSessionDetailServerUnreachable =>
      'Impossible de joindre le serveur.';

  @override
  String get clientSessionDetailReviewPublishedSnack =>
      'Avis publié avec succès !';

  @override
  String get clientSessionDetailReviewPublishErrorSnack =>
      'Erreur lors de la publication.';

  @override
  String get clientSessionDetailDialogBack => 'RETOUR';

  @override
  String get clientSessionDetailTopBarTitle => 'Détails de la séance';

  @override
  String clientSessionDetailBannerPriceProposed(String price) {
    return '$price MAD · proposé';
  }

  @override
  String clientSessionDetailBannerPriceMad(int price) {
    return '$price MAD';
  }

  @override
  String get clientSessionDetailBannerFreeSession => 'Séance gratuite';

  @override
  String get clientSessionDetailBannerAwaitingPricing => 'En attente du tarif';

  @override
  String clientSessionDetailDurationTimeRange(
      int minutes, String start, String end) {
    return '$minutes min · $start — $end';
  }

  @override
  String clientSessionDetailPerSessionPackage(String packageName) {
    return 'Par séance · $packageName';
  }

  @override
  String get clientSessionDetailInfoDate => 'Date';

  @override
  String get clientSessionDetailInfoTime => 'Heure';

  @override
  String get clientSessionDetailInfoDuration => 'Durée';

  @override
  String clientSessionDetailDurationMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get clientSessionDetailInfoLocation => 'Lieu';

  @override
  String get clientSessionDetailLocationDefault =>
      'Lieu à définir avec le coach par message';

  @override
  String get clientSessionDetailInfoPackage => 'Forfait';

  @override
  String get clientSessionDetailInfoRef => 'Réf.';

  @override
  String get clientSessionDetailCoachFallback => 'Coach';

  @override
  String get clientSessionDetailAnywhereFallback => 'Partout';

  @override
  String get clientSessionDetailNewCoach => 'Nouveau';

  @override
  String get clientSessionDetailBtnCancel => 'ANNULER';

  @override
  String get clientSessionDetailApprovalExpiredReason =>
      'Le coach n\'a pas approuvé cette réservation avant l\'échéance d\'une heure.';

  @override
  String get clientSessionDetailPriceNotAgreedReason =>
      'Le tarif n\'a pas été convenu avant l\'échéance de deux heures.';

  @override
  String get clientSessionDetailRequestExpiredTitle => 'Demande expirée';

  @override
  String get clientSessionDetailCancellationReasonTitle =>
      'Motif d\'annulation';

  @override
  String get clientSessionDetailShareReviewTitle => 'Partagez votre avis';

  @override
  String get clientSessionDetailShareReviewSubtitle =>
      'Aidez les autres à choisir le bon coach';

  @override
  String get clientSessionDetailPublishedBadge => 'PUBLIÉ';

  @override
  String get clientSessionDetailEditMyReview => 'Modifier mon avis';

  @override
  String get clientSessionDetailCancelEditing => 'Annuler la modification';

  @override
  String get clientSessionDetailCommentLabel => 'Commentaire';

  @override
  String get clientSessionDetailHowWasSession =>
      'Comment s\'est passée votre séance ?';

  @override
  String get clientSessionDetailReviewHint =>
      'Partagez les détails... (facultatif)';

  @override
  String get clientSessionDetailUpdateMyReviewBtn => 'Mettre à jour';

  @override
  String get clientSessionDetailPublishMyReviewBtn => 'Publier l\'avis';

  @override
  String get clientSessionDetailRating1 => 'À améliorer';

  @override
  String get clientSessionDetailRating2 => 'Correct';

  @override
  String get clientSessionDetailRating3 => 'Bien';

  @override
  String get clientSessionDetailRating4 => 'Très bien';

  @override
  String get clientSessionDetailRating5 => 'Excellent !';

  @override
  String get clientConversationDeletedMessage => 'Ce message a été supprimé';

  @override
  String get clientConversationSelectLimitError =>
      'Sélectionnez jusqu\'à 100 messages à la fois.';

  @override
  String clientConversationDeleteDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count messages ?',
      one: 'Supprimer 1 message ?',
    );
    return '$_temp0';
  }

  @override
  String get clientConversationDeleteDialogContent =>
      'La suppression pour tout le monde est disponible pour vos propres messages pendant les 30 premières minutes.';

  @override
  String get clientConversationCancel => 'Annuler';

  @override
  String get clientConversationDeleteForMe => 'Supprimer pour moi';

  @override
  String get clientConversationDeleteForEveryone =>
      'Supprimer pour tout le monde';

  @override
  String get clientConversationDeleteFailed =>
      'Impossible de supprimer les messages.';

  @override
  String get clientConversationRefreshError =>
      'Impossible d\'actualiser les messages. Vérifiez votre connexion.';

  @override
  String get clientConversationSendRetryError =>
      'Envoi impossible. Votre message est prêt à être renvoyé.';

  @override
  String get clientConversationAttachCamera => 'Appareil photo';

  @override
  String get clientConversationAttachGallery => 'Galerie';

  @override
  String get clientConversationCaptionHint => 'Ajouter une légende...';

  @override
  String get clientConversationSend => 'Envoyer';

  @override
  String get clientConversationImageUploadFailed =>
      'Échec de l\'envoi de l\'image';

  @override
  String get clientConversationSendPhotoError =>
      'Impossible d\'envoyer la photo. Veuillez réessayer.';

  @override
  String get clientConversationBatchLimitError =>
      'Choisissez jusqu\'à 30 photos par envoi.';

  @override
  String clientConversationBatchFailedError(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count photos n\'ont pas pu être envoyées. Les autres ont été envoyées.',
      one: '1 photo n\'a pas pu être envoyée. Les autres ont été envoyées.',
    );
    return '$_temp0';
  }

  @override
  String get clientConversationAudioUploadFailed =>
      'Échec de l\'envoi de l\'audio';

  @override
  String get clientConversationMicPermissionError =>
      'Autorisez l\'accès au microphone pour Sirvya dans les réglages de votre téléphone afin d\'enregistrer des messages vocaux.';

  @override
  String get clientConversationAudioRecordError =>
      'Impossible d\'enregistrer ou d\'envoyer l\'audio. Veuillez réessayer.';

  @override
  String get clientConversationMediaSendFailed => 'Échec de l\'envoi du média';

  @override
  String get clientConversationNetworkError => 'Erreur réseau';

  @override
  String get clientConversationTitleFallback => 'Conversation';

  @override
  String get clientConversationSubtitleFallback => 'Coach sportif';

  @override
  String get clientConversationMenuSelect => 'Sélectionner des messages';

  @override
  String get clientConversationMenuRefresh => 'Actualiser les messages';

  @override
  String get clientConversationMenuReport => 'Signaler le coach';

  @override
  String get clientConversationMenuBlock => 'Bloquer le coach';

  @override
  String get clientConversationReportReasonSpam => 'Spam';

  @override
  String get clientConversationReportReasonHarassment => 'Harcèlement';

  @override
  String get clientConversationReportReasonInappropriate =>
      'Contenu inapproprié';

  @override
  String get clientConversationReportReasonFraud => 'Fraude / Arnaque';

  @override
  String get clientConversationReportReasonOther => 'Autre';

  @override
  String get clientConversationThisCoachFallback => 'ce coach';

  @override
  String clientConversationReportTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String get clientConversationReportPrompt =>
      'Pourquoi signalez-vous cet utilisateur ? Nous prenons ces signalements très au sérieux.';

  @override
  String get clientConversationSubmit => 'Envoyer';

  @override
  String get clientConversationIdentifyCoachReportError =>
      'Impossible d\'identifier le coach à signaler';

  @override
  String get clientConversationReportSubmitted =>
      'Signalement envoyé avec succès.';

  @override
  String get clientConversationReportFailed =>
      'Échec de l\'envoi du signalement';

  @override
  String clientConversationBlockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get clientConversationBlockMessage =>
      'Cet utilisateur ne pourra plus trouver votre profil ni vous envoyer de messages. Il ne sera pas informé de ce blocage.';

  @override
  String get clientConversationBlockConfirm => 'Bloquer';

  @override
  String get clientConversationIdentifyCoachBlockError =>
      'Impossible d\'identifier le coach à bloquer';

  @override
  String get clientConversationUserBlocked => 'Utilisateur bloqué.';

  @override
  String get clientConversationBlockFailed =>
      'Échec du blocage de l\'utilisateur';

  @override
  String get coachAccountBack => 'Retour';

  @override
  String get coachAccountCancel => 'Annuler';

  @override
  String coachAccountCopiedToClipboard(String label) {
    return '$label copié dans le presse-papiers';
  }

  @override
  String get coachAccountDeleteCannotNow =>
      'Impossible de supprimer le compte pour le moment.';

  @override
  String get coachAccountDeleteCheckEmailSubtitle =>
      'Consultez votre e-mail pour le code de confirmation à 6 chiffres.';

  @override
  String get coachAccountDeleteCodeExpired => 'Code expiré.';

  @override
  String coachAccountDeleteCodeExpiresIn(String mins, String secs) {
    return 'Le code expire dans $mins:$secs';
  }

  @override
  String get coachAccountDeleteConfirmButton => 'Supprimer le compte';

  @override
  String get coachAccountDeleteEnterCodeInstructions =>
      'Saisissez le code envoyé par e-mail pour confirmer la suppression.';

  @override
  String get coachAccountDeleteItem1 =>
      'Votre profil de coach et sa visibilité publique';

  @override
  String get coachAccountDeleteItem2 =>
      'Vos forfaits, photos et certifications';

  @override
  String get coachAccountDeleteItem3 =>
      'L’historique de vos conversations et liens clients';

  @override
  String get coachAccountDeleteItem4 =>
      'Toutes vos réservations passées et en cours';

  @override
  String get coachAccountDeletePermanentSubtitle =>
      'Cette action est irréversible.';

  @override
  String get coachAccountDeleteResendCode => 'Renvoyer le code';

  @override
  String get coachAccountDeleteSendCodeButton => 'Envoyer le code';

  @override
  String get coachAccountDeleteSendCodeFailed =>
      'Échec de l’envoi du code. Veuillez réessayer.';

  @override
  String get coachAccountDeleteTitle => 'Supprimer le compte coach';

  @override
  String get coachAccountDeleteUnderstandCheckbox =>
      'Je comprends que la suppression de mon compte est définitive.';

  @override
  String get coachAccountDeleteVerifyTitle => 'Confirmer la suppression';

  @override
  String get coachAccountDeleteWhatWillBeDeleted =>
      'Les données suivantes seront définitivement supprimées :';

  @override
  String get coachAccountEnterFullCode =>
      'Veuillez saisir le code complet à 6 chiffres.';

  @override
  String get coachAccountServerUnreachable =>
      'Serveur injoignable. Vérifiez votre connexion.';

  @override
  String get coachAccountThemeDark => 'Sombre';

  @override
  String get coachAccountThemeLight => 'Clair';

  @override
  String get coachAccountThemeSystem => 'Système';

  @override
  String get coachAccountVerificationFailed =>
      'La vérification a échoué. Veuillez réessayer.';

  @override
  String get coachCalendarActionAccept => 'Accepter';

  @override
  String get coachCalendarActionAwaitingClient => 'En attente du client';

  @override
  String get coachCalendarActionCancelReservation => 'Annuler la réservation';

  @override
  String get coachCalendarActionProposePrice => 'Proposer un tarif';

  @override
  String get coachCalendarActionReject => 'Refuser';

  @override
  String get coachCalendarAddBlockedPeriod => 'Bloquer un créneau';

  @override
  String get coachCalendarAwaitingYourPriceOffer =>
      'En attente de votre offre de prix';

  @override
  String get coachCalendarBlockHours => 'Bloquer des heures spécifiques';

  @override
  String get coachCalendarBlockSpecificHoursSubtitle =>
      'Sélectionnez la plage horaire à rendre indisponible.';

  @override
  String get coachCalendarBlockTheseHours => 'Bloquer ces heures';

  @override
  String get coachCalendarBlockedPeriodsSubtitle =>
      'Créneaux marqués comme indisponibles pour les clients.';

  @override
  String get coachCalendarBlockedPeriodsTitle => 'Périodes bloquées';

  @override
  String get coachCalendarCancel => 'Annuler';

  @override
  String get coachCalendarCancelDialogTitle => 'Annuler la réservation';

  @override
  String get coachCalendarConfirm => 'Confirmer';

  @override
  String coachCalendarDurationMinutes(int duration) {
    return '$duration min';
  }

  @override
  String get coachCalendarEnterReasonHint => 'Motif (facultatif)';

  @override
  String get coachCalendarFailed => 'L’opération a échoué. Veuillez réessayer.';

  @override
  String get coachCalendarLegendBlocked => 'Bloqué';

  @override
  String get coachCalendarLegendReservation => 'Réservation';

  @override
  String get coachCalendarLocationArranged => 'Lieu convenu avec le client';

  @override
  String get coachCalendarLocationGym => 'Salle de sport';

  @override
  String get coachCalendarLocationHome => 'À domicile';

  @override
  String get coachCalendarNoBlockedPeriods =>
      'Aucune période bloquée pour cette date.';

  @override
  String get coachCalendarNoReservationsThisDay =>
      'Aucune réservation prévue ce jour.';

  @override
  String get coachCalendarNoteOptionalHint => 'Note (facultatif)';

  @override
  String coachCalendarPriceAwaitingClient(String price) {
    return '$price MAD proposé · En attente du client';
  }

  @override
  String coachCalendarPricePerSession(String price) {
    return '$price MAD / séance';
  }

  @override
  String get coachCalendarPricePerSessionLabel => 'Tarif par séance (MAD)';

  @override
  String get coachCalendarProposePriceBody =>
      'Indiquez votre proposition de tarif pour cette séance.';

  @override
  String get coachCalendarProposePriceTitle => 'Proposer un tarif';

  @override
  String get coachCalendarRejectDialogTitle => 'Refuser la réservation';

  @override
  String get coachCalendarReservationDetailsTitle =>
      'Détails de la réservation';

  @override
  String coachCalendarReservationNumber(String id) {
    return 'Réservation n°$id';
  }

  @override
  String get coachCalendarReservationUnavailable =>
      'Informations de réservation indisponibles.';

  @override
  String get coachCalendarSendOffer => 'Envoyer l’offre';

  @override
  String get coachCalendarSendPriceError =>
      'Veuillez entrer un montant valide.';

  @override
  String get coachCalendarSlotBooked => 'Créneau réservé';

  @override
  String get coachCalendarStatusCancelled => 'Annulée';

  @override
  String get coachCalendarStatusConfirmed => 'Confirmée';

  @override
  String get coachCalendarStatusExpired => 'Expirée';

  @override
  String get coachCalendarStatusPending => 'En attente';

  @override
  String get coachCalendarStatusPriceDeclined => 'Tarif refusé';

  @override
  String get coachCalendarStatusPriceOffered => 'Tarif proposé';

  @override
  String get coachCalendarTabAvailability => 'Disponibilités';

  @override
  String get coachCalendarTabReservations => 'Réservations';

  @override
  String get coachCalendarTimeEnd => 'Heure de fin';

  @override
  String get coachCalendarTimeStart => 'Heure de début';

  @override
  String get coachCalendarTitle => 'Calendrier';

  @override
  String coachCalendarWorkingHours(int start, int end) {
    return 'Horaires : $start:00 – $end:00';
  }

  @override
  String get coachDashboardActivitySubtitle =>
      'Voici l’aperçu de votre activité.';

  @override
  String coachDashboardAgreedPrices(String period) {
    return 'Tarifs convenus ($period)';
  }

  @override
  String get coachDashboardClientFallback => 'Client';

  @override
  String get coachDashboardCoachFallback => 'Coach';

  @override
  String coachDashboardDaysAgoLong(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $days jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String coachDashboardDaysAgoShort(int days) {
    return 'il y a ${days}j';
  }

  @override
  String get coachDashboardFilterThisMonth => 'Ce mois';

  @override
  String get coachDashboardFilterThisWeek => 'Cette semaine';

  @override
  String get coachDashboardFilterToday => 'Aujourd’hui';

  @override
  String get coachDashboardGoodMorning => 'Bonjour';

  @override
  String coachDashboardHoursAgoLong(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'il y a $hours heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String coachDashboardHoursAgoShort(int hours) {
    return 'il y a ${hours}h';
  }

  @override
  String get coachDashboardInvitationPoints => 'Points d’invitation';

  @override
  String get coachDashboardInvitations => 'Invitations';

  @override
  String coachDashboardInvitationsThisWeek(int count) {
    return '$count cette semaine';
  }

  @override
  String get coachDashboardJustNow => 'À l’instant';

  @override
  String get coachDashboardLoadErrorSubtitle =>
      'Impossible de charger les données du tableau de bord.';

  @override
  String get coachDashboardLoadErrorTitle => 'Erreur de chargement';

  @override
  String coachDashboardMinutesAgoLong(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'il y a $minutes minutes',
      one: 'il y a 1 minute',
    );
    return '$_temp0';
  }

  @override
  String coachDashboardMinutesAgoShort(int minutes) {
    return 'il y a ${minutes}m';
  }

  @override
  String get coachDashboardNoNotificationsSubtitle =>
      'Les notifications et rappels apparaîtront ici.';

  @override
  String get coachDashboardNoNotificationsTitle => 'Aucune notification';

  @override
  String get coachDashboardNoUpcomingReservationsSubtitle =>
      'Vos prochaines réservations apparaîtront ici.';

  @override
  String get coachDashboardNoUpcomingReservationsTitle =>
      'Aucune séance à venir';

  @override
  String get coachDashboardNotificationFallback => 'Notification';

  @override
  String get coachDashboardNotificationsTitle => 'Notifications';

  @override
  String coachDashboardPeriodClients(int count, String period) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients ($period)',
      one: '1 client ($period)',
    );
    return '$_temp0';
  }

  @override
  String get coachDashboardPeriodThisMonth => 'ce mois';

  @override
  String get coachDashboardPeriodThisWeek => 'cette semaine';

  @override
  String get coachDashboardPeriodToday => 'aujourd’hui';

  @override
  String get coachDashboardRecentReservations => 'Réservations récentes';

  @override
  String get coachDashboardRetry => 'Réessayer';

  @override
  String get coachDashboardSetYourAvailability => 'Définir vos disponibilités';

  @override
  String get coachDashboardStatClients => 'Clients';

  @override
  String get coachDashboardStatReservations => 'Réservations';

  @override
  String get coachDashboardStatRevenue => 'Revenus (MAD)';

  @override
  String coachDashboardTierLabel(int tier) {
    return 'Niveau : $tier';
  }

  @override
  String get coachDashboardTitle => 'Tableau de bord';

  @override
  String get coachDashboardTotalClients => 'Total clients';

  @override
  String get coachDashboardUpcomingReservations => 'Séances à venir';

  @override
  String get coachDashboardViewAll => 'Voir tout';

  @override
  String coachDashboardWantsToConnect(String timeAgo) {
    return 'Souhaite se connecter · $timeAgo';
  }

  @override
  String get coachEditProfileAdd => 'Ajouter';

  @override
  String get coachEditProfileAddCertificationButton =>
      'Ajouter une certification';

  @override
  String get coachEditProfileAddCertificationHint =>
      'ex. Préparateur physique diplômé';

  @override
  String get coachEditProfileAddCertificationTitle =>
      'Ajouter une certification';

  @override
  String get coachEditProfileAddGalleryImageButton => 'Ajouter une photo';

  @override
  String get coachEditProfileAddPackageButton => 'Ajouter un forfait';

  @override
  String get coachEditProfileAddSpecialtyButton => 'Ajouter une spécialité';

  @override
  String get coachEditProfileAddSpecialtyHint => 'Sélectionnez une spécialité';

  @override
  String get coachEditProfileAddSpecialtyTitle => 'Ajouter une spécialité';

  @override
  String get coachEditProfileBioHint =>
      'Partagez votre parcours et votre vision du coaching.';

  @override
  String get coachEditProfileBioLabel => 'Biographie';

  @override
  String get coachEditProfileBioTitle => 'À propos de vous';

  @override
  String get coachEditProfileCancel => 'Annuler';

  @override
  String get coachEditProfileCertificationsSubtitle =>
      'Mettez en avant vos diplômes et certifications.';

  @override
  String get coachEditProfileCertificationsTitle => 'Certifications';

  @override
  String get coachEditProfileCityHint => 'ex. Casablanca';

  @override
  String get coachEditProfileCityLabel => 'Ville';

  @override
  String coachEditProfileDeletePackageConfirm(String name) {
    return 'Supprimer le forfait « $name » ?';
  }

  @override
  String get coachEditProfileDeletePackageTitle => 'Supprimer le forfait';

  @override
  String get coachEditProfileDeletePhotoConfirm =>
      'Supprimer cette photo de votre galerie ?';

  @override
  String get coachEditProfileDeletePhotoTitle => 'Supprimer la photo';

  @override
  String get coachEditProfileExperienceHint => 'ex. 5 ans';

  @override
  String get coachEditProfileExperienceLabel => 'Expérience';

  @override
  String get coachEditProfileGallerySubtitle =>
      'Des photos professionnelles inspirent confiance.';

  @override
  String get coachEditProfileGalleryTitle => 'Galerie photos';

  @override
  String get coachEditProfileHourlyRateHint => 'ex. 300';

  @override
  String get coachEditProfileHourlyRateLabel => 'Tarif horaire (MAD)';

  @override
  String get coachEditProfileInstagramHint => 'ex. coach_fitness';

  @override
  String get coachEditProfileInstagramLabel => 'Instagram';

  @override
  String coachEditProfilePackageSessionsChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '1 séance',
    );
    return '$_temp0';
  }

  @override
  String get coachEditProfilePackagesSubtitle =>
      'Proposez des packs de séances ou programmes.';

  @override
  String get coachEditProfilePackagesTitle => 'Forfaits de coaching';

  @override
  String get coachEditProfilePersonalInfoTitle => 'Informations personnelles';

  @override
  String get coachEditProfilePhoneLabel => 'Numéro de téléphone';

  @override
  String get coachEditProfileProfessionalTitle => 'Titre professionnel';

  @override
  String get coachEditProfileProfessionalTitleHint =>
      'ex. Coach Sportif & Préparateur Physique';

  @override
  String get coachEditProfileSave => 'Enregistrer';

  @override
  String get coachEditProfileSaveSuccess => 'Profil mis à jour avec succès.';

  @override
  String get coachEditProfileSaving => 'Enregistrement…';

  @override
  String get coachEditProfileSpecialtiesSubtitle =>
      'Aidez les clients à vous trouver selon vos spécialités.';

  @override
  String get coachEditProfileSpecialtiesTitle => 'Spécialités';

  @override
  String get coachEditProfileTitle => 'Modifier le profil';

  @override
  String get coachProfileAboutConfigured => 'Biographie configurée';

  @override
  String get coachProfileAboutDefault => 'Aucune biographie pour le moment.';

  @override
  String get coachProfileCancel => 'Annuler';

  @override
  String get coachProfileCoachFallback => 'Coach';

  @override
  String get coachProfileCompletedSnack => 'Profil complété !';

  @override
  String get coachProfileEditProfile => 'Modifier le profil';

  @override
  String coachProfileInfoExperience(String exp) {
    return 'Expérience : $exp';
  }

  @override
  String coachProfileInfoLanguages(String lang) {
    return 'Langues : $lang';
  }

  @override
  String get coachProfileInfoLocation => 'Localisation';

  @override
  String get coachProfileInfoProfessionalTitle => 'Titre';

  @override
  String get coachProfileInfoSpecialties => 'Spécialités';

  @override
  String get coachProfileLoadError => 'Impossible de charger le profil.';

  @override
  String get coachProfileLoading => 'Chargement du profil…';

  @override
  String get coachProfileLocationNotSet => 'Emplacement non défini';

  @override
  String get coachProfileLogOutConfirmMessage =>
      'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get coachProfileLogOutTitle => 'Déconnexion';

  @override
  String get coachProfileMenuAboutYou => 'À propos de vous';

  @override
  String get coachProfileMenuAccount => 'Paramètres du compte';

  @override
  String get coachProfileMenuExpertise => 'Expertise et spécialités';

  @override
  String get coachProfileMenuFeedback => 'Mes avis';

  @override
  String get coachProfileMenuFeedbackSubtitle =>
      'Avis et évaluations des clients';

  @override
  String get coachProfileMenuLocations => 'Lieux d’entraînement';

  @override
  String get coachProfileMenuLocationsSubtitle => 'Gérer vos salles et zones';

  @override
  String get coachProfileMenuPackages => 'Forfaits et tarifs';

  @override
  String get coachProfileMenuPackagesSubtitle => 'Définir vos tarifs';

  @override
  String get coachProfileMenuPhotos => 'Galerie photos';

  @override
  String get coachProfileMenuVisibility => 'Visibilité du profil';

  @override
  String get coachProfileNotSet => 'Non renseigné';

  @override
  String get coachProfilePersonalTrainerFallback => 'Coach Sportif';

  @override
  String get coachProfilePhotoUpdated => 'Photo de profil mise à jour.';

  @override
  String coachProfilePhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get coachProfilePreviewProfile => 'Aperçu public';

  @override
  String get coachProfileProfessionalInfoEmpty =>
      'Aucune information renseignée.';

  @override
  String get coachProfileProfessionalInformationSection =>
      'Informations professionnelles';

  @override
  String get coachProfilePublicProfileBadge => 'Public';

  @override
  String get coachProfileRetry => 'Réessayer';

  @override
  String get coachProfileSaveError => 'Impossible d’enregistrer le profil.';

  @override
  String get coachProfileStatBookings => 'Réservations';

  @override
  String get coachProfileStatClients => 'Clients';

  @override
  String get coachProfileStatPoints => 'Points';

  @override
  String get coachProfileStepAvatar => 'Ajoutez une photo de profil.';

  @override
  String get coachProfileStepBio => 'Ajoutez votre biographie.';

  @override
  String get coachProfileStepCertifications => 'Ajoutez vos certifications.';

  @override
  String get coachProfileStepCity => 'Indiquez votre ville.';

  @override
  String get coachProfileStepClientLevels =>
      'Précisez le niveau des clients acceptés.';

  @override
  String get coachProfileStepCoachingFormats =>
      'Choisissez vos formats de coaching.';

  @override
  String get coachProfileStepEmail => 'Ajoutez votre adresse e-mail.';

  @override
  String get coachProfileStepExperience => 'Indiquez vos années d’expérience.';

  @override
  String get coachProfileStepFirstName => 'Indiquez votre prénom.';

  @override
  String get coachProfileStepGallery => 'Ajoutez des photos à votre galerie.';

  @override
  String get coachProfileStepGender => 'Indiquez votre genre.';

  @override
  String get coachProfileStepGymAddress => 'Ajoutez l’adresse de la salle.';

  @override
  String get coachProfileStepGymImage => 'Ajoutez une photo de la salle.';

  @override
  String get coachProfileStepGymName => 'Indiquez le nom de la salle.';

  @override
  String get coachProfileStepInstagram => 'Ajoutez votre compte Instagram.';

  @override
  String get coachProfileStepLanguages => 'Indiquez les langues parlées.';

  @override
  String get coachProfileStepLastName => 'Indiquez votre nom de famille.';

  @override
  String get coachProfileStepPackage => 'Créez un forfait de coaching.';

  @override
  String get coachProfileStepPhone => 'Ajoutez votre numéro de téléphone.';

  @override
  String get coachProfileStepProfessionalTitle =>
      'Indiquez votre titre professionnel.';

  @override
  String get coachProfileStepServiceArea =>
      'Définissez votre zone d’intervention.';

  @override
  String get coachProfileStepSpecialties => 'Sélectionnez vos spécialités.';

  @override
  String get coachProfileTitle => 'Profil coach';

  @override
  String get coachProfileUploadFailed => 'Échec du téléchargement de la photo.';

  @override
  String get coachClientDetailDisconnectInviteTitle => 'Dissocier l’invitation';

  @override
  String coachClientDetailDisconnectInviteMessage(String name) {
    return 'Dissocier votre invitation avec $name ? Les clients ayant des réservations restent visibles pour gérer leurs séances.';
  }

  @override
  String get coachClientDetailCancel => 'Annuler';

  @override
  String get coachClientDetailDisconnect => 'Dissocier';

  @override
  String get coachClientDetailTitle => 'Client';

  @override
  String get coachClientDetailLoadError => 'Impossible de charger le client';

  @override
  String get coachClientDetailRetry => 'Réessayer';

  @override
  String get coachClientDetailNoSessions => 'Aucune séance pour le moment';

  @override
  String get coachClientDetailReport => 'Signaler le client';

  @override
  String get coachClientDetailBlock => 'Bloquer le client';

  @override
  String coachClientDetailReportTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String get coachClientDetailReportSubtitle =>
      'Pourquoi signalez-vous cet utilisateur ? Nous traitons ces signalements avec sérieux.';

  @override
  String get coachClientDetailSubmit => 'Envoyer';

  @override
  String coachClientDetailBlockTitle(String name) {
    return 'Bloquer $name ? ';
  }

  @override
  String get coachClientDetailBlockMessage =>
      'Cette personne ne pourra plus réserver de séances ni vous envoyer de messages.';

  @override
  String get coachClientDetailBlockConfirm => 'Bloquer';

  @override
  String get coachDashboardStatConfirmed => 'Confirmées';

  @override
  String get coachDashboardStatConfirmedValue => 'Séances confirmées';

  @override
  String get coachDashboardStatPending => 'En attente';

  @override
  String coachDashboardStatusAcceptedPoints(String points) {
    return '+$points pts';
  }

  @override
  String get coachDashboardStatusCancelled => 'Annulée';

  @override
  String get coachDashboardStatusConfirmed => 'Confirmée';

  @override
  String get coachDashboardStatusDeclined => 'Refusée';

  @override
  String get coachDashboardStatusPending => 'En attente';

  @override
  String get coachDashboardStatusUnknown => 'Inconnu';

  @override
  String coachDashboardTierProgress(int progress, int nextTier, int remaining) {
    return '$progress% vers $nextTier · $remaining pts restants';
  }

  @override
  String get coachDashboardTomorrow => 'Demain';

  @override
  String get coachDashboardYesterday => 'Hier';

  @override
  String get coachProfileCompletionTitle => 'Complétion du profil';

  @override
  String get coachProfileGalleryPreview => 'Aperçu de la galerie';

  @override
  String get coachProfileInfoBio => 'Biographie';

  @override
  String get coachProfileInfoCertifications => 'Certifications';

  @override
  String get coachEditProfileAddOtherSpecialty =>
      '+ Ajouter une autre spécialité';

  @override
  String get coachEditProfileAddPackageTitle => 'Ajouter un forfait';

  @override
  String get coachEditProfileBioRequired => 'La biographie est obligatoire.';

  @override
  String get coachEditProfileCertificationExists =>
      'Cette certification a déjà été ajoutée.';

  @override
  String get coachEditProfileCustomSpecialties => 'Spécialités personnalisées';

  @override
  String get coachEditProfileDelete => 'Supprimer';

  @override
  String get coachEditProfileDirectMessagingSubtitle =>
      'Permettre aux clients potentiels de vous contacter avant de réserver.';

  @override
  String get coachEditProfileDirectMessagingTitle => 'Messagerie directe';

  @override
  String get coachEditProfileEditPackageTitle => 'Modifier le forfait';

  @override
  String get coachEditProfileEmailHint => 'votre.email@exemple.com';

  @override
  String get coachEditProfileEmailInvalid =>
      'Veuillez entrer une adresse e-mail valide.';

  @override
  String get coachEditProfileEmailLabel => 'Adresse e-mail';

  @override
  String get coachEditProfileEmailRequired =>
      'L\'adresse e-mail est obligatoire.';

  @override
  String get coachEditProfileEnterFullName =>
      'Veuillez saisir votre nom complet.';

  @override
  String get coachEditProfileFullNameLabel => 'Nom complet';

  @override
  String get coachEditProfileFullNameValidator =>
      'Veuillez saisir votre nom complet.';

  @override
  String get coachEditProfileGalleryAdded => 'Photo ajoutée à la galerie.';

  @override
  String get coachEditProfileGalleryEmpty => 'Aucune photo dans votre galerie.';

  @override
  String get coachEditProfileGalleryMaxImages =>
      'Maximum 12 photos autorisées dans la galerie.';

  @override
  String get coachEditProfileGenderFemale => 'Femme';

  @override
  String get coachEditProfileGenderLabel => 'Genre';

  @override
  String get coachEditProfileGenderMale => 'Homme';

  @override
  String get coachEditProfileGenderOther => 'Autre';

  @override
  String get coachEditProfileGenericError =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get coachEditProfileImageDeleted => 'Photo supprimée de la galerie.';

  @override
  String get coachEditProfileMaxCertifications =>
      'Maximum 10 certifications autorisées.';

  @override
  String get coachEditProfileMaxPackagesReached =>
      'Limite de forfaits atteinte.';

  @override
  String get coachEditProfileMaxSpecialties =>
      'Maximum 8 spécialités autorisées.';

  @override
  String get coachEditProfileNoCertifications =>
      'Aucune certification ajoutée pour le moment.';

  @override
  String get coachEditProfilePackageAdded => 'Forfait créé avec succès.';

  @override
  String get coachEditProfilePackageDeleted => 'Forfait supprimé.';

  @override
  String get coachEditProfilePackageDescriptionHint =>
      'Décrivez ce qui est inclus dans ce forfait...';

  @override
  String get coachEditProfilePackageDescriptionLabel =>
      'Description du forfait';

  @override
  String get coachEditProfilePackageHidden => 'Masqué pour les clients';

  @override
  String get coachEditProfilePackageNameHint => 'ex. Pack Démarrage 10 séances';

  @override
  String get coachEditProfilePackageNameLabel => 'Nom du forfait';

  @override
  String get coachEditProfilePackageNameRequired =>
      'Le nom du forfait est requis.';

  @override
  String get coachEditProfilePackageSessionsHint => 'Nombre de séances';

  @override
  String get coachEditProfilePackageSessionsLabel => 'Séances incluses';

  @override
  String get coachEditProfilePackageSetPriceSubtitle =>
      'Les clients verront ce prix lors de la réservation.';

  @override
  String get coachEditProfilePackageSetPriceTitle => 'Prix de la séance';

  @override
  String get coachEditProfilePackageUpdated =>
      'Forfait mis à jour avec succès.';

  @override
  String get coachEditProfilePackageVisibleToClients =>
      'Visible par les clients sur votre profil';

  @override
  String get coachEditProfilePackagesDescription =>
      'Gérez les forfaits et offres de séances affichés sur votre profil public.';

  @override
  String get coachEditProfilePhoneHint => '+212 6XX XXX XXX';

  @override
  String get coachEditProfilePhotoReady => 'Photo prête à être enregistrée.';

  @override
  String get coachEditProfilePriceOnRequest => 'Tarif sur demande';

  @override
  String get coachEditProfileProfessionalTitleLabel => 'Titre professionnel';

  @override
  String get coachEditProfilePublicProfileSubtitle =>
      'Permettre aux clients de trouver votre profil dans les recherches.';

  @override
  String get coachEditProfilePublicProfileTitle => 'Profil public';

  @override
  String get coachEditProfileSaveChangesButton => 'Enregistrer';

  @override
  String get coachEditProfileSectionAccountSettings => 'Paramètres du compte';

  @override
  String get coachEditProfileSectionBasicInfo => 'Informations de base';

  @override
  String get coachEditProfileSectionCertifications =>
      'Diplômes et certifications';

  @override
  String get coachEditProfileSectionContactLocation =>
      'Contact et localisation';

  @override
  String get coachEditProfileSectionGallery => 'Galerie photos';

  @override
  String get coachEditProfileSectionPackages => 'Forfaits et tarifs';

  @override
  String get coachEditProfileSectionSpecialties => 'Spécialités de coaching';

  @override
  String get coachEditProfileSpecialtiesDescription =>
      'Sélectionnez vos spécialités pour attirer les bons clients.';

  @override
  String get coachEditProfileSpecialtyExists =>
      'Cette spécialité a déjà été ajoutée.';

  @override
  String get coachEditProfileSubtitle =>
      'Maintenez vos informations à jour pour attirer plus de clients.';

  @override
  String get coachEditProfileUpdate => 'Mettre à jour';

  @override
  String get coachEditProfileUpdateError =>
      'Échec de la mise à jour du profil.';

  @override
  String get coachEditProfileUpdatedSnack => 'Profil mis à jour avec succès.';

  @override
  String get coachEditProfileUploadFailed => 'Échec de l\'envoi de la photo.';

  @override
  String coachDashboardPercentOfTotal(String percent) {
    return '$percent% du total';
  }

  @override
  String get coachDashboardVerificationPendingTitle => 'Vérification en cours';

  @override
  String get coachDashboardVerificationPendingBody =>
      'Vos justificatifs sont en cours d\'examen par l\'équipe SIRVYA.';

  @override
  String coachEditProfileErrorWithDetail(String detail) {
    return 'Erreur : $detail';
  }

  @override
  String coachEditProfileGalleryLimitWarning(int max) {
    return 'Vous ne pouvez ajouter que $max photos au maximum.';
  }

  @override
  String coachEditProfileUploadFailedForFile(String file) {
    return 'Échec de l\'envoi de $file';
  }

  @override
  String get coachEditProfileImageDeleteFailed =>
      'Impossible de supprimer l\'image.';

  @override
  String coachEditProfileNetworkError(String error) {
    return 'Erreur réseau : $error';
  }

  @override
  String coachProfileErrorWithDetail(String detail) {
    return 'Erreur : $detail';
  }

  @override
  String get coachCalendarBlockAction => 'Bloquer';

  @override
  String get coachAccountTitle => 'Compte et parrainages';

  @override
  String get coachAccountReferralTitle => 'Parrainage coach';

  @override
  String get coachAccountReferralSubtitle =>
      'Invitez des confrères et gagnez des récompenses';

  @override
  String get coachAccountCopy => 'Copier';

  @override
  String get coachAccountCode => 'Code';

  @override
  String get coachAccountScanToInvite => 'Scannez pour inviter';

  @override
  String get coachAccountCopyCode => 'Copier le code';

  @override
  String coachAccountReferralRewardDesc(int points) {
    return 'Gagnez $points points bonus pour chaque coach professionnel que vous intégrez à l\'écosystème SIRVYA.';
  }

  @override
  String get coachAccountPrivateAccount => 'Compte privé';

  @override
  String get coachAccountEmail => 'E-mail';

  @override
  String get coachAccountChangeEmailSubtitle =>
      'Modifier l\'adresse e-mail avec vérification.';

  @override
  String get coachAccountEmailUpdated => 'E-mail mis à jour avec succès';

  @override
  String get coachAccountPhone => 'Téléphone';

  @override
  String get coachAccountPhoneUpdated => 'Téléphone mis à jour avec succès';

  @override
  String get coachAccountPasswordSecurity => 'Mot de passe et sécurité';

  @override
  String get coachAccountPasswordUpdated =>
      'Mot de passe mis à jour avec succès';

  @override
  String get coachAccountAppearance => 'Apparence';

  @override
  String get coachAccountChooseAppTheme =>
      'Choisissez le thème de l\'application';

  @override
  String get coachAccountNotifications => 'Notifications';

  @override
  String get coachAccountBlockedUsers => 'Utilisateurs bloqués';

  @override
  String get coachAccountDeleteAccount => 'Supprimer le compte';

  @override
  String get coachChatAudioRecordError =>
      'Impossible d’enregistrer la note vocale. Vérifiez les autorisations.';

  @override
  String get coachChatAudioUploadFailed => 'Échec de l’envoi du message audio.';

  @override
  String coachChatBatchPartialFail(int failed) {
    return '$failed images n’ont pas pu être envoyées.';
  }

  @override
  String get coachChatBlock => 'Bloquer';

  @override
  String get coachChatBlockClient => 'Bloquer le client';

  @override
  String get coachChatBlockContent =>
      'Êtes-vous sûr de vouloir bloquer ce client ? Il ne pourra plus vous contacter ni réserver.';

  @override
  String get coachChatBlockFailed => 'Échec du blocage du client.';

  @override
  String get coachChatBlockIdentifyError =>
      'Impossible d’identifier le client à bloquer.';

  @override
  String get coachChatBlockSuccess => 'Client bloqué avec succès.';

  @override
  String coachChatBlockTitle(String name) {
    return 'Bloquer $name ?';
  }

  @override
  String get coachChatCamera => 'Appareil photo';

  @override
  String get coachChatCancel => 'Annuler';

  @override
  String get coachChatCaptionHint => 'Ajouter une légende...';

  @override
  String get coachChatDeleteFailed => 'Impossible de supprimer le message.';

  @override
  String get coachChatDeleteForEveryone => 'Supprimer pour tout le monde';

  @override
  String get coachChatDeleteForMe => 'Supprimer pour moi';

  @override
  String get coachChatDeleteMessagesContent =>
      'Supprimer les messages sélectionnés ?';

  @override
  String coachChatDeleteMessagesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return 'Supprimer $_temp0 ?';
  }

  @override
  String get coachChatGallery => 'Galerie';

  @override
  String get coachChatHeaderSubtitle => 'Client actif';

  @override
  String get coachChatImageUploadFailed => 'Échec de l’envoi de l’image.';

  @override
  String get coachChatMaxBatchPhotos => '10 photos maximum par message.';

  @override
  String get coachChatMaxSelection => '20 messages sélectionnés au maximum.';

  @override
  String get coachChatMicrophonePermission =>
      'L’accès au micro est requis pour les notes vocales.';

  @override
  String get coachChatNetworkError => 'Erreur réseau. Veuillez réessayer.';

  @override
  String get coachChatPhotoSendError => 'Impossible d’envoyer la photo.';

  @override
  String get coachChatReasonFraud => 'Fraude ou escroquerie';

  @override
  String get coachChatReasonHarassment => 'Harcèlement ou abus';

  @override
  String get coachChatReasonInappropriate => 'Contenu inapproprié';

  @override
  String get coachChatReasonOther => 'Autre motif';

  @override
  String get coachChatReasonSpam => 'Spam ou publicité';

  @override
  String get coachChatRefreshError => 'Impossible d’actualiser les messages.';

  @override
  String get coachChatRefreshMessages => 'Actualiser les messages';

  @override
  String get coachChatReportClient => 'Signaler le client';

  @override
  String get coachChatReportFailed => 'Échec de l’envoi du signalement.';

  @override
  String get coachChatReportIdentifyError =>
      'Impossible d’identifier le client.';

  @override
  String get coachChatReportPrompt => 'Sélectionnez un motif de signalement :';

  @override
  String get coachChatReportSuccess =>
      'Signalement envoyé. Merci de nous aider à protéger la communauté.';

  @override
  String coachChatReportTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String get coachChatSelectMessages => 'Sélectionner des messages';

  @override
  String get coachChatSend => 'Envoyer';

  @override
  String get coachChatSendFailed => 'Impossible d’envoyer le message.';

  @override
  String get coachChatSubmit => 'Envoyer';

  @override
  String get coachChatThisClient => 'ce client';

  @override
  String get coachExpertiseAdd => 'Ajouter';

  @override
  String get coachExpertiseAddCertTitle => 'Ajouter une certification';

  @override
  String get coachExpertiseAddSpecialtyTitle => 'Ajouter une spécialité';

  @override
  String get coachExpertiseAttachedDocument => 'Document joint';

  @override
  String get coachExpertiseCancel => 'Annuler';

  @override
  String get coachExpertiseCertDetailsTitle => 'Détails de la certification';

  @override
  String get coachExpertiseCertNameHint => 'Nom de la certification';

  @override
  String get coachExpertiseCertProviderHint => 'Organisme certificateur';

  @override
  String get coachExpertiseCertYearHint => 'Année d’obtention';

  @override
  String get coachExpertiseCertificationsSubtitle =>
      'Affichez vos diplômes et certifications vérifiés.';

  @override
  String get coachExpertiseCertificationsTitle => 'Certifications';

  @override
  String get coachExpertiseCoachingSince => 'Coach depuis';

  @override
  String get coachExpertiseDetailName => 'Nom';

  @override
  String get coachExpertiseDetailProvider => 'Organisme';

  @override
  String get coachExpertiseDetailYear => 'Année';

  @override
  String coachExpertiseErrorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get coachExpertiseExperienceSubtitle =>
      'Votre expérience cumulée en coaching.';

  @override
  String get coachExpertiseExperienceTitle => 'Expérience';

  @override
  String coachExpertiseExperienceYears(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years ans',
      one: '1 an',
    );
    return '$_temp0';
  }

  @override
  String get coachExpertiseFileAttached => 'Fichier joint';

  @override
  String get coachExpertiseLevelsSubtitle =>
      'Niveaux des clients que vous accompagnez.';

  @override
  String get coachExpertiseLevelsTitle => 'Niveaux clients';

  @override
  String get coachExpertiseNoCerts => 'Aucune certification ajoutée.';

  @override
  String get coachExpertiseNoSpecialties => 'Aucune spécialité sélectionnée.';

  @override
  String get coachExpertiseRetry => 'Réessayer';

  @override
  String get coachExpertiseSave => 'Enregistrer';

  @override
  String get coachExpertiseSaveSuccess => 'Expertise mise à jour avec succès.';

  @override
  String get coachExpertiseSaving => 'Enregistrement…';

  @override
  String get coachExpertiseSelectDoc => 'Téléverser le justificatif';

  @override
  String get coachExpertiseSpecialtiesSubtitle =>
      'Sélectionnez vos domaines d’expertise.';

  @override
  String get coachExpertiseSpecialtiesTitle => 'Spécialités';

  @override
  String get coachExpertiseTitle => 'Expertise et compétences';

  @override
  String get coachExpertiseUploadFailed =>
      'Échec du téléversement du document.';

  @override
  String get coachExpertiseYearsLabel => 'Années d’expérience';

  @override
  String get coachLocationsAddressHint => 'Adresse ou repère';

  @override
  String get coachLocationsAddressLabel => 'Adresse';

  @override
  String get coachLocationsCancel => 'Annuler';

  @override
  String get coachLocationsCityTitle => 'Ville principale';

  @override
  String get coachLocationsDetectCityHint =>
      'Appuyez pour détecter votre ville';

  @override
  String get coachLocationsEditGymDialogTitle => 'Modifier la salle de sport';

  @override
  String get coachLocationsEditLocation => 'Modifier le lieu';

  @override
  String get coachLocationsFormatGym => 'En salle de sport';

  @override
  String get coachLocationsFormatHome => 'À domicile';

  @override
  String get coachLocationsFormatOnline => 'En ligne';

  @override
  String get coachLocationsFormatsSubtitle =>
      'Où dispensez-vous vos séances de coaching ?';

  @override
  String get coachLocationsFormatsTitle => 'Formats de coaching';

  @override
  String get coachLocationsGymAddressHint => 'Adresse de la salle';

  @override
  String get coachLocationsGymAddressLabel => 'Adresse de la salle';

  @override
  String get coachLocationsGymNameHint => 'ex. City Club';

  @override
  String get coachLocationsGymNameLabel => 'Nom de la salle';

  @override
  String get coachLocationsGymSubtitle =>
      'Votre salle de sport ou studio partenaire.';

  @override
  String get coachLocationsGymTitle => 'Salle partenaire';

  @override
  String get coachLocationsRadiusHint => 'Rayon de déplacement (km)';

  @override
  String get coachLocationsRadiusLabel => 'Rayon de déplacement (km)';

  @override
  String get coachLocationsSave => 'Enregistrer les lieux';

  @override
  String get coachLocationsSaveSuccess => 'Lieux mis à jour avec succès.';

  @override
  String get coachLocationsSaving => 'Enregistrement…';

  @override
  String get coachLocationsTitle => 'Lieux d’entraînement';

  @override
  String get coachPackagesAddPackage => 'Ajouter un forfait';

  @override
  String get coachPackagesAgreeOnPrice => 'Tarif convenu avec le client';

  @override
  String get coachPackagesCancel => 'Annuler';

  @override
  String get coachPackagesDelete => 'Supprimer';

  @override
  String get coachPackagesDeleteContent =>
      'Êtes-vous sûr de vouloir supprimer ce forfait ?';

  @override
  String get coachPackagesDeleteError => 'Impossible de supprimer le forfait.';

  @override
  String get coachPackagesDeleteTitle => 'Supprimer le forfait';

  @override
  String get coachPackagesDeleted => 'Forfait supprimé.';

  @override
  String get coachPackagesDurationLabel => 'Durée';

  @override
  String get coachPackagesEdit => 'Modifier';

  @override
  String get coachPackagesEditPackage => 'Modifier le forfait';

  @override
  String get coachPackagesEmptySubtitle =>
      'Créez des forfaits pour fidéliser vos clients.';

  @override
  String get coachPackagesEmptyTitle => 'Aucun forfait pour le moment';

  @override
  String get coachPackagesNameHint => 'ex. Pack Transformation 10 séances';

  @override
  String get coachPackagesNameLabel => 'Nom du forfait';

  @override
  String get coachPackagesPriceHint => 'Prix en MAD';

  @override
  String get coachPackagesPriceLabel => 'Prix (MAD)';

  @override
  String coachPackagesProgress(int current, int max) {
    return '$current sur $max forfaits';
  }

  @override
  String get coachPackagesSave => 'Enregistrer le forfait';

  @override
  String get coachPackagesSaveError => 'Impossible d’enregistrer le forfait.';

  @override
  String get coachPackagesSaved => 'Forfait enregistré avec succès.';

  @override
  String get coachPackagesSaving => 'Enregistrement…';

  @override
  String coachPackagesSessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séances',
      one: '1 séance',
    );
    return '$_temp0';
  }

  @override
  String get coachPackagesSessionsHint => 'Nombre de séances incluses';

  @override
  String get coachPackagesSessionsLabel => 'Séances incluses';

  @override
  String get coachPackagesTitle => 'Forfaits et tarifs';

  @override
  String get coachPhotosAddPhoto => 'Ajouter une photo';

  @override
  String get coachPhotosAddressHint => 'Adresse de la salle';

  @override
  String get coachPhotosAddressLabel => 'Adresse';

  @override
  String get coachPhotosCancel => 'Annuler';

  @override
  String get coachPhotosCaptionHint => 'Légende (facultatif)';

  @override
  String get coachPhotosCaptionTitle => 'Légende de la photo';

  @override
  String get coachPhotosCover => 'Couverture';

  @override
  String get coachPhotosDelete => 'Supprimer';

  @override
  String get coachPhotosEditCaption => 'Modifier la légende';

  @override
  String get coachPhotosEditGymDialogTitle => 'Modifier la photo de salle';

  @override
  String coachPhotosErrorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get coachPhotosGallerySubtitle =>
      'Présentez vos séances et votre cadre d’entraînement.';

  @override
  String get coachPhotosGalleryTitle => 'Photos de galerie';

  @override
  String get coachPhotosGymTitle => 'Photos de la salle / studio';

  @override
  String get coachPhotosNoPhotos => 'Aucune photo dans votre galerie.';

  @override
  String coachPhotosPartialSlots(int slots) {
    return '$slots emplacements restants.';
  }

  @override
  String coachPhotosSaveFailed(String error) {
    return 'Impossible d’enregistrer la photo : $error';
  }

  @override
  String get coachPhotosSaveSuccess => 'Photos mises à jour avec succès.';

  @override
  String get coachPhotosSaving => 'Enregistrement…';

  @override
  String get coachPhotosTitle => 'Photos du coach';

  @override
  String get coachPhotosUploadFailed => 'Échec du téléversement de la photo.';

  @override
  String get mealScannerAddFoodItem => 'Ajouter un aliment';

  @override
  String get mealScannerAddToMeal => 'Ajouter au repas';

  @override
  String get mealScannerAdjustPortion => 'Ajuster la portion';

  @override
  String get mealScannerApply => 'Appliquer';

  @override
  String get mealScannerCalculatedNutrition =>
      'Valeurs nutritionnelles calculées';

  @override
  String get mealScannerCaloriesKcalLabel => 'Calories (kcal)';

  @override
  String get mealScannerCarbsGLabel => 'Glucides (g)';

  @override
  String get mealScannerCategoryAll => 'Tous';

  @override
  String get mealScannerCategoryDairy => 'Produits laitiers & Œufs';

  @override
  String get mealScannerCategoryDrinks => 'Boissons';

  @override
  String get mealScannerCategoryFish => 'Poissons & Fruits de mer';

  @override
  String get mealScannerCategoryGrains => 'Céréales & Féculents';

  @override
  String get mealScannerCategoryMeals => 'Plats préparés';

  @override
  String get mealScannerCategoryMeat => 'Viandes & Volailles';

  @override
  String get mealScannerCategoryNuts => 'Graines & Fruits secs';

  @override
  String get mealScannerCategoryProduce => 'Fruits & Légumes';

  @override
  String get mealScannerCategorySnacks => 'Snacks & Douceurs';

  @override
  String get mealScannerChangesNotSynced =>
      'Enregistré localement · Non synchronisé';

  @override
  String get mealScannerChooseCategoryHint => 'Choisir la catégorie';

  @override
  String get mealScannerChooseDifferentFood => 'Choisir un autre aliment';

  @override
  String get mealScannerCustomFoodDefaultName => 'Aliment personnalisé';

  @override
  String get mealScannerCustomFoodNameLabel => 'Nom de l’aliment';

  @override
  String get mealScannerCustomItemFallback => 'Aliment';

  @override
  String get mealScannerDeleteMeal => 'Supprimer le repas';

  @override
  String get mealScannerEditMacrosManually =>
      'Modifier les macros manuellement';

  @override
  String get mealScannerEnterFoodNameError =>
      'Veuillez entrer un nom d’aliment.';

  @override
  String get mealScannerEnterValidWeightError =>
      'Veuillez entrer un poids valide en grammes.';

  @override
  String get mealScannerFatGLabel => 'Lipides (g)';

  @override
  String mealScannerFoodMacrosPer100g(
      int calories, String protein, String carbs, String fat) {
    return '$calories kcal · P ${protein}g · G ${carbs}g · L ${fat}g';
  }

  @override
  String get mealScannerFoodNameLabel => 'Nom de l’aliment';

  @override
  String get mealScannerMacroCarbs => 'Glucides';

  @override
  String get mealScannerMacroFat => 'Lipides';

  @override
  String get mealScannerMacroProtein => 'Protéines';

  @override
  String get mealScannerManualValuesActive => 'Valeurs manuelles actives';

  @override
  String get mealScannerMealBreakfast => 'Petit-déjeuner';

  @override
  String mealScannerMealDate(String date) {
    return 'Date du repas : $date';
  }

  @override
  String get mealScannerMealDinner => 'Dîner';

  @override
  String get mealScannerMealLunch => 'Déjeuner';

  @override
  String mealScannerMealMovedTo(String meal) {
    return 'Repas déplacé vers $meal';
  }

  @override
  String mealScannerMealSavedTo(String meal) {
    return 'Repas enregistré dans $meal';
  }

  @override
  String get mealScannerMealSnack => 'Collation';

  @override
  String get mealScannerMoveMeal => 'Déplacer le repas';

  @override
  String mealScannerNoFoodsFound(String query) {
    return 'Aucun aliment trouvé pour « $query »';
  }

  @override
  String mealScannerNotSynced(String meal) {
    return 'Non synchronisé ($meal)';
  }

  @override
  String get mealScannerOneServing => '1 portion';

  @override
  String get mealScannerOnlineBadge => 'En ligne';

  @override
  String get mealScannerOrEnterCustomMacros =>
      'Ou saisir les macros personnalisées';

  @override
  String get mealScannerProteinGLabel => 'Protéines (g)';

  @override
  String mealScannerQuantityLabel(String unit) {
    return 'Quantité ($unit)';
  }

  @override
  String get mealScannerQueryingGlobalDb =>
      'Recherche dans la base alimentaire…';

  @override
  String get mealScannerResetToAuto => 'Réinitialiser les calculs';

  @override
  String mealScannerSavedIn(String meal) {
    return 'Enregistré dans $meal';
  }

  @override
  String get mealScannerSearchHint => 'Rechercher ou scanner un code-barres…';

  @override
  String get mealScannerSearchMoreOnline => 'Rechercher en ligne';

  @override
  String get mealScannerSearchOpenFoodFacts => 'Recherche Open Food Facts';

  @override
  String mealScannerSearchingFor(String query) {
    return 'Recherche de « $query »…';
  }

  @override
  String get mealScannerSearchingOnlineBanner => 'Recherche en ligne…';

  @override
  String get mealScannerSearchingOnlineShort => 'Recherche…';

  @override
  String mealScannerSelectedFoodBase(
      int calories, String protein, String carbs, String fat) {
    return '$calories kcal · P ${protein}g · G ${carbs}g · L ${fat}g (pour 100g)';
  }

  @override
  String get mealScannerValuesAutoCalculated =>
      'Valeurs calculées automatiquement selon le poids.';

  @override
  String nutritionGoalAboutMaintenanceKcal(int kcal) {
    return '$kcal kcal/jour estimées pour maintien';
  }

  @override
  String get nutritionGoalActivityHigh => 'Élevée (sport quotidien intense)';

  @override
  String get nutritionGoalActivityLight => 'Légère (1-2 entraînements/semaine)';

  @override
  String get nutritionGoalActivityLow => 'Sédentaire (peu ou pas d’exercice)';

  @override
  String get nutritionGoalActivityModerate =>
      'Modérée (3-5 entraînements/semaine)';

  @override
  String get nutritionGoalAdultWeightError =>
      'Veuillez entrer un poids cible réaliste.';

  @override
  String get nutritionGoalAgeLabel => 'Âge';

  @override
  String nutritionGoalAppliedToast(
      int calories, int protein, int carbs, int fat) {
    return 'Cibles appliquées : $calories kcal · P ${protein}g · G ${carbs}g · L ${fat}g';
  }

  @override
  String get nutritionGoalApplyRecommendedBtn =>
      'Appliquer les objectifs recommandés';

  @override
  String get nutritionGoalBreakfastCheckin => 'Rappel petit-déjeuner';

  @override
  String get nutritionGoalCalorieCheckinsSub =>
      'Recevez des rappels quotidiens pour vos repas.';

  @override
  String get nutritionGoalCalorieCheckinsTitle => 'Rappels de suivi des repas';

  @override
  String get nutritionGoalCaptionDailyEnergy =>
      'Apport calorique quotidien cible';

  @override
  String get nutritionGoalCaptionHormoneHealth =>
      'Essentiel pour l’équilibre hormonal';

  @override
  String get nutritionGoalCaptionMuscleRecovery =>
      'Cible pour la récupération musculaire et satiété';

  @override
  String get nutritionGoalCompleteProfilePrompt =>
      'Complétez votre profil pour des objectifs sur-mesure.';

  @override
  String nutritionGoalDeficitBadge(int diff) {
    return 'Déficit de $diff kcal';
  }

  @override
  String get nutritionGoalDietBalanced => 'Équilibrée';

  @override
  String get nutritionGoalDietHalal => 'Halal';

  @override
  String get nutritionGoalDietVegan => 'Végétalienne';

  @override
  String get nutritionGoalDietVegetarian => 'Végétarienne';

  @override
  String get nutritionGoalDietaryStyleLabel => 'Préférence alimentaire';

  @override
  String get nutritionGoalDinnerCheckin => 'Rappel dîner';

  @override
  String get nutritionGoalEstimateMaintenanceSub =>
      'Calculé d’après votre taille, poids, âge et activité.';

  @override
  String get nutritionGoalEstimateMaintenanceTitle => 'Calories de maintien';

  @override
  String get nutritionGoalEstimatePrompt =>
      'Calculez vos cibles caloriques et macro-nutritionnelles.';

  @override
  String nutritionGoalFieldInvalid(String field) {
    return 'Veuillez entrer une valeur valide pour $field';
  }

  @override
  String nutritionGoalFieldRequired(String field) {
    return '$field est obligatoire';
  }

  @override
  String get nutritionGoalFoodPreferenceLabel => 'Préférence alimentaire';

  @override
  String get nutritionGoalGeneralEstimatesSuitable =>
      'Ces estimations constituent une base fiable adaptée à vos besoins.';

  @override
  String get nutritionGoalHeaderSubtitle =>
      'Définissez vos objectifs caloriques et macro-nutritionnels.';

  @override
  String get nutritionGoalHeaderTitle => 'Objectifs nutritionnels';

  @override
  String get nutritionGoalHeightLabel => 'Taille (cm)';

  @override
  String get nutritionGoalLunchCheckin => 'Rappel déjeuner';

  @override
  String get nutritionGoalMacroCalories => 'Calories';

  @override
  String get nutritionGoalMacroCarbs => 'Glucides';

  @override
  String get nutritionGoalMacroFat => 'Lipides';

  @override
  String get nutritionGoalMacroProtein => 'Protéines';

  @override
  String get nutritionGoalMaintenanceBadge => 'Maintien';

  @override
  String get nutritionGoalMealIdeasSub =>
      'Recevez des suggestions de recettes adaptées.';

  @override
  String get nutritionGoalMealIdeasTitle => 'Idées de repas';

  @override
  String get nutritionGoalMinorSectionSub => 'Préférences et calendrier';

  @override
  String get nutritionGoalMinorSectionTitle => 'Préférences';

  @override
  String get nutritionGoalMonthlyReview => 'Bilan mensuel des progrès';

  @override
  String get nutritionGoalMyGoalLabel => 'Objectif principal';

  @override
  String get nutritionGoalNoteGain =>
      'Viser la prise de masse musculaire avec un surplus modéré.';

  @override
  String get nutritionGoalNoteLose =>
      'Viser une perte de masse grasse durable avec un déficit modéré.';

  @override
  String get nutritionGoalNoteMaintain =>
      'Viser la stabilité du poids, la forme et l’énergie.';

  @override
  String get nutritionGoalQuietHoursEnd => 'Fin des heures calmes';

  @override
  String get nutritionGoalQuietHoursNote =>
      'Les notifications sont mises en sourdine pendant ces heures.';

  @override
  String get nutritionGoalQuietHoursStart => 'Début des heures calmes';

  @override
  String get nutritionGoalRecommendedTitle => 'Cibles recommandées';

  @override
  String get nutritionGoalRemindersSub => 'Gérer vos rappels et heures calmes.';

  @override
  String get nutritionGoalRemindersTitle => 'Rappels et notifications';

  @override
  String get nutritionGoalSaveMyGoal => 'Enregistrer mon objectif';

  @override
  String get nutritionGoalSaving => 'Enregistrement…';

  @override
  String get nutritionGoalSectionDailyTargetsSub =>
      'Personnalisez la répartition de vos macronutriments.';

  @override
  String get nutritionGoalSectionDailyTargetsTitle => 'Cibles quotidiennes';

  @override
  String get nutritionGoalSectionStatusSub =>
      'Statut de cet objectif nutritionnel.';

  @override
  String get nutritionGoalSectionStatusTitle => 'Statut de l’objectif';

  @override
  String get nutritionGoalSectionSupportSub =>
      'Rappels et conseils de votre coach.';

  @override
  String get nutritionGoalSectionSupportTitle => 'Accompagnement & Rappels';

  @override
  String get nutritionGoalSectionWhatMattersSub =>
      'L’essentiel pour votre progression.';

  @override
  String get nutritionGoalSectionWhatMattersTitle => 'Focus nutritionnel';

  @override
  String get nutritionGoalSetupLaterInProfile =>
      'Vous pourrez modifier ces cibles à tout moment dans votre profil.';

  @override
  String get nutritionGoalSexFemale => 'Femme';

  @override
  String get nutritionGoalSexMale => 'Homme';

  @override
  String get nutritionGoalSkipForNow => 'Passer cette étape';

  @override
  String get nutritionGoalStartFreshSub =>
      'Réinitialiser les cibles selon les recommandations.';

  @override
  String get nutritionGoalStartFreshTitle => 'Réinitialiser les cibles';

  @override
  String get nutritionGoalStartingWeightLabel => 'Poids de départ (kg)';

  @override
  String get nutritionGoalStatusAchieved => 'Atteint';

  @override
  String get nutritionGoalStatusActive => 'Actif';

  @override
  String get nutritionGoalStatusPaused => 'En pause';

  @override
  String get nutritionGoalStyleBalanced => 'Équilibré';

  @override
  String get nutritionGoalStyleHighProtein => 'Riche en protéines';

  @override
  String get nutritionGoalStyleLowCarb => 'Faible en glucides';

  @override
  String nutritionGoalSurplusBadge(int diff) {
    return 'Surplus de $diff kcal';
  }

  @override
  String get nutritionGoalTargetDirectionError =>
      'La direction du poids cible ne correspond pas à l’objectif choisi.';

  @override
  String get nutritionGoalTargetWeightLabel => 'Poids cible (kg)';

  @override
  String get nutritionGoalTimeZoneLabel => 'Fuseau horaire';

  @override
  String get nutritionGoalTitle => 'Objectif nutritionnel';

  @override
  String get nutritionGoalTitleSignup => 'Définir votre objectif nutritionnel';

  @override
  String get nutritionGoalTypeBalanced => 'Forme générale';

  @override
  String get nutritionGoalTypeGain => 'Prise de masse';

  @override
  String get nutritionGoalTypeLose => 'Perte de poids';

  @override
  String get nutritionGoalTypeMaintain => 'Maintien';

  @override
  String get nutritionGoalUnitKcalPerDay => 'kcal / jour';

  @override
  String get nutritionGoalUseThisGoal => 'Utiliser cet objectif';

  @override
  String get nutritionGoalUsualActivityLabel => 'Niveau d’activité habituel';

  @override
  String get nutritionGoalWeeklyWeightCheckin => 'Pesée hebdomadaire';

  @override
  String get nutritionGoalYearlyReview => 'Bilan annuel';

  @override
  String get nutritionTrackerGoalLoadError =>
      'Impossible de charger votre objectif. Veuillez réessayer.';

  @override
  String get nutritionTrackerMealRemoveError =>
      'Impossible de supprimer ce repas. Réessayez.';

  @override
  String get nutritionTrackerDailyDiary => 'VOTRE JOURNAL QUOTIDIEN';

  @override
  String get nutritionTrackerFuelDay => 'Faites le plein d’énergie.';

  @override
  String get nutritionTrackerBackToToday => 'Revenir à aujourd’hui';

  @override
  String get nutritionTrackerRetrySync => 'Réessayer la synchronisation';

  @override
  String get nutritionTrackerEnergyLogged => 'ÉNERGIE ENREGISTRÉE';

  @override
  String nutritionTrackerMealsLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repas enregistrés',
      one: '1 repas enregistré',
    );
    return '$_temp0';
  }

  @override
  String get nutritionTrackerSetDailyTargets =>
      'Définir vos objectifs quotidiens →';

  @override
  String get nutritionTrackerScanMeal => 'Scanner un repas';

  @override
  String get nutritionTrackerAddManually => 'Ajouter manuellement';

  @override
  String get nutritionTrackerMealsMoments => 'Repas et moments';

  @override
  String get nutritionTrackerDiaryTitle => 'Journal de nutrition';

  @override
  String get nutritionTrackerNothingLogged =>
      'Rien d’enregistré pour l’instant';

  @override
  String get nutritionTrackerAddMealTitle => 'Ajouter un repas';

  @override
  String get nutritionTrackerAddMealSubtitle =>
      'Utilisez les valeurs nutritionnelles de l’étiquette ou de votre recette.';

  @override
  String get nutritionTrackerMealNameLabel => 'Nom du repas';

  @override
  String get nutritionTrackerSaving => 'Enregistrement…';

  @override
  String get nutritionTrackerSaveMeal => 'Enregistrer le repas';

  @override
  String get nutritionTrackerDailyTargetsTitle => 'Vos objectifs quotidiens';

  @override
  String get nutritionTrackerSaveTargets => 'Enregistrer les objectifs';

  @override
  String get coachExpertiseDetailStatus => 'Statut de vérification';

  @override
  String get coachExpertiseErrorPickingFile =>
      'Impossible de sélectionner le fichier.';

  @override
  String get coachExpertiseErrorUpdating =>
      'Échec de la mise à jour des compétences.';

  @override
  String get coachExpertiseFailedLoadDoc =>
      'Impossible de charger le justificatif.';

  @override
  String get coachExpertiseFileUploaded => 'Justificatif téléversé.';

  @override
  String get coachExpertiseLevelAdvanced => 'Athlètes avancés';

  @override
  String get coachExpertiseLevelBeginners => 'Débutants';

  @override
  String get coachExpertiseLevelIntermediate => 'Intermédiaire';

  @override
  String get coachExpertiseMaxSpecialties =>
      'Maximum 8 spécialités autorisées.';

  @override
  String get coachExpertisePreview => 'Aperçu';

  @override
  String get coachExpertisePrimaryCategory => 'Discipline principale';

  @override
  String get coachExpertiseProfileUpdated =>
      'Compétences mises à jour avec succès.';

  @override
  String get coachExpertiseResubmit => 'Renvoyer le document';

  @override
  String get coachExpertiseReviewInProgress =>
      'En cours de vérification par l\'équipe SIRVYA';

  @override
  String get coachExpertiseReviewNotice =>
      'Les certificats sont vérifiés par notre équipe sous 24 à 48h.';

  @override
  String get coachExpertiseSaveChanges => 'Enregistrer';

  @override
  String get coachExpertiseSelectCategory =>
      'Sélectionnez la catégorie principale';

  @override
  String get coachExpertiseSelectYear => 'Sélectionnez l\'année';

  @override
  String get coachExpertiseSpecialtyHint => 'ex. Entraînement Kettlebell';

  @override
  String get coachExpertiseStatusApproved => 'Vérifié';

  @override
  String get coachExpertiseStatusRejected => 'Refusé';

  @override
  String get coachExpertiseStatusReviewing => 'En cours de vérification';

  @override
  String get coachExpertiseStatusSelfReported => 'Déclaratif';

  @override
  String get coachExpertiseSubmitVerification => 'Soumettre pour vérification';

  @override
  String get coachExpertiseSuggestedBodybuilding =>
      'Musculation & Hypertrophie';

  @override
  String get coachExpertiseSuggestedConditioning => 'Cardio & Conditionnement';

  @override
  String get coachExpertiseSuggestedForYou => 'Suggéré pour votre discipline';

  @override
  String get coachExpertiseSuggestedFunctional => 'Entraînement fonctionnel';

  @override
  String get coachExpertiseSuggestedNutrition => 'Nutrition & Diététique';

  @override
  String get coachExpertiseSuggestedPilates => 'Pilates & Gainage';

  @override
  String get coachExpertiseSuggestedPowerlifting =>
      'Force athlétique & Powerlifting';

  @override
  String get coachExpertiseSuggestedRehabilitation =>
      'Réathlétisation & Post-rééducation';

  @override
  String get coachExpertiseSuggestedYoga => 'Yoga & Souplesse';

  @override
  String get coachExpertiseTapToPreview => 'Appuyez pour voir le certificat';

  @override
  String get coachExpertiseUploadCertificate =>
      'Téléverser le certificat (PDF / Image)';

  @override
  String get coachExpertiseVerifiedBadgeInfo =>
      'Les compétences vérifiées reçoivent un badge sur votre profil public.';

  @override
  String get coachExpertiseVerifiedCertificate => 'Certificat vérifié';

  @override
  String get coachExpertiseViewDetails => 'Voir les détails';

  @override
  String get coachExpertiseWhoYouCoach =>
      'Quel public entraînez-vous habituellement ?';

  @override
  String get coachLocationsFormatOutdoors => 'En extérieur / Parcs';

  @override
  String get coachLocationsGymLocationTitle => 'Emplacement de la salle';

  @override
  String get coachLocationsManageAvailability =>
      'Gérer vos créneaux de coaching';

  @override
  String get coachLocationsOpenCalendar => 'Horaires et calendrier';

  @override
  String get coachLocationsPreview => 'Aperçu';

  @override
  String get coachLocationsSaveChanges => 'Enregistrer';

  @override
  String coachLocationsSaveFailed(String error) {
    return 'Impossible d\'enregistrer le lieu : $error';
  }

  @override
  String get coachLocationsSelectGym => 'Sélectionner la salle partenaire';

  @override
  String get coachLocationsServiceAreaHint => 'ex. Grand Casablanca';

  @override
  String get coachLocationsServiceAreaSubtitle =>
      'Zones où vous vous déplacez pour vos clients.';

  @override
  String get coachLocationsServiceAreaTitle => 'Zone d\'intervention';

  @override
  String get coachLocationsUpdateLocation => 'Mettre à jour les coordonnées';

  @override
  String get coachLocationsUploadImage => 'Téléverser une photo';

  @override
  String get coachLocationsUploading => 'Téléversement en cours…';

  @override
  String get coachPackagesFixedPrice => 'Tarif fixe par séance';

  @override
  String get coachPackagesFixedPriceSub =>
      'Tarif appliqué par défaut pour une séance.';

  @override
  String get coachPackagesIncludedHint =>
      'ex. Plan alimentaire + suivi WhatsApp 7j/7';

  @override
  String get coachPackagesIncludedLabel => 'Ce qui est inclus';

  @override
  String get coachPackagesIndividualSession => 'Séance individuelle';

  @override
  String get coachPackagesLocationGym => 'Salle';

  @override
  String get coachPackagesLocationOnline => 'En ligne';

  @override
  String get coachPackagesLocationsLabel => 'Lieux disponibles';

  @override
  String get coachPackagesMinutesUnit => 'min';

  @override
  String coachPackagesMultipleSessions(int sessions, int duration) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions séances',
      one: '1 séance',
    );
    return '$_temp0 · $duration min chacune';
  }

  @override
  String get coachPackagesOnRequest => 'Sur demande';

  @override
  String get coachPackagesPerSession => 'MAD / séance';

  @override
  String get coachPackagesPreview => 'Aperçu';

  @override
  String get coachPackagesPriceOnRequest => 'Tarif sur demande';

  @override
  String get coachPackagesPricingLabel => 'Modèle de tarification';

  @override
  String get coachPackagesSaveChanges => 'Enregistrer';

  @override
  String get coachPhotosFormatGym => 'Salle';

  @override
  String get coachPhotosFormatHome => 'Domicile';

  @override
  String get coachPhotosFormatOnline => 'En ligne';

  @override
  String get coachPhotosFormatOutdoors => 'Extérieur';

  @override
  String get coachPhotosGymNameHint => 'Nom de la salle';

  @override
  String get coachPhotosGymNameLabel => 'Nom de la salle';

  @override
  String get coachPhotosMaxPhotos => 'Limite de 12 photos atteinte.';

  @override
  String get coachPhotosPortfolioSubtitle =>
      'Des photos professionnelles inspirent confiance aux futurs clients.';

  @override
  String get coachPhotosPortfolioTitle => 'Portfolio de coaching';

  @override
  String get coachPhotosPreview => 'Aperçu';

  @override
  String get coachPhotosSave => 'Enregistrer';

  @override
  String get coachPhotosSaveChanges => 'Enregistrer';

  @override
  String get coachPhotosUploadImage => 'Téléverser une photo';

  @override
  String get coachPhotosUploading => 'Téléversement…';

  @override
  String coachLocationsErrorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get nutritionGoalBiologicalSexLabel => 'Sexe biologique';

  @override
  String get nutritionGoalSexEstimateLabel =>
      'Utilisé pour le calcul du métabolisme de base';

  @override
  String get nutritionGoalGeneralEstimatesSub =>
      'Équations nutritionnelles standard basées sur votre profil';

  @override
  String get nutritionGoalUseMaintenanceBtn =>
      'Utiliser les cibles de maintien';

  @override
  String get nutritionGoalAboutCaloriePlanning =>
      'À propos de la planification calorique';

  @override
  String get nutritionTrackerDailyTargetsTooltip => 'Objectifs quotidiens';

  @override
  String get nutritionTrackerPrevDayTooltip => 'Jour précédent';

  @override
  String get nutritionTrackerNextDayTooltip => 'Jour suivant';

  @override
  String get nutritionTrackerToday => 'Aujourd\'hui';

  @override
  String nutritionTrackerTargetSummary(int goal) {
    return 'Objectif de $goal kcal';
  }

  @override
  String nutritionTrackerRemaining(int diff) {
    return '$diff restant';
  }

  @override
  String nutritionTrackerAboveTarget(int diff) {
    return '$diff au-dessus';
  }

  @override
  String nutritionTrackerOfGrams(int goal) {
    return 'sur $goal g';
  }

  @override
  String get nutritionTrackerNoTargetSet => 'Aucun objectif';

  @override
  String get nutritionTrackerEstimatesNotice =>
      'Les estimations nutritionnelles sont basées sur vos portions enregistrées. Les détails des repas se synchronisent avec votre compte. Votre journal suit les dates choisies.';

  @override
  String nutritionTrackerShareMealTooltip(String name) {
    return 'Partager $name';
  }

  @override
  String nutritionTrackerRemoveMealTooltip(String name) {
    return 'Supprimer $name';
  }

  @override
  String get nutritionTrackerManualNotes => 'Nutrition saisie manuellement.';

  @override
  String get nutritionTrackerOneServing => '1 portion';

  @override
  String get nutritionTrackerSyncError =>
      'Impossible de synchroniser votre journal. Vérifiez votre connexion et réessayez.';

  @override
  String get nutritionTrackerSyncMealError =>
      'Impossible de synchroniser ce repas. Vos données sont conservées ; réessayez.';

  @override
  String get nutritionTrackerEnterMealName => 'Saisissez un nom de repas';

  @override
  String get nutritionTrackerChooseMealTypeNotice =>
      'Choisissez Petit-déjeuner, Déjeuner, Dîner ou Collation après avoir appuyé sur Enregistrer.';

  @override
  String get nutritionTrackerEnterValidNumber =>
      'Saisissez un nombre valide, y compris 0';

  @override
  String get nutritionTrackerSaveTargetsError =>
      'Impossible d\'enregistrer les objectifs. Vos données sont conservées.';

  @override
  String get nutritionTrackerSetTargetsSubtitle =>
      'Définissez les objectifs adaptés à votre programme. Laissez un champ vide pour suivre sans objectif.';

  @override
  String get nutritionTrackerEnterValidDailyTarget =>
      'Saisissez un objectif quotidien valide';

  @override
  String get themeServiceLight => 'Clair';

  @override
  String get themeServiceDark => 'Sombre';

  @override
  String get themeServiceSystem => 'Système';

  @override
  String get themeSelectorAppearance => 'Apparence';

  @override
  String get themeSelectorChooseTheme =>
      'Choisissez le thème de l\'application';

  @override
  String get campaignServiceAnnouncementExpired =>
      'Cette annonce a expiré ou n\'est plus disponible.';

  @override
  String get campaignServiceOpenLinkFailed => 'Impossible d\'ouvrir ce lien.';

  @override
  String get campaignServiceLocationTbd => 'À définir';

  @override
  String get campaignServiceCompanyIndependent => 'Indépendant';

  @override
  String get locationReminderTitleCoach =>
      'Aidez les clients à proximité à vous trouver';

  @override
  String get locationReminderTitleClient =>
      'Trouvez des coachs plus proches de vous';

  @override
  String get locationReminderBodyCoach =>
      'Activez la localisation pour permettre aux clients de vous découvrir à proximité et de voir une distance approximative. Seules votre ville et la distance sont affichées ; votre adresse reste confidentielle.';

  @override
  String get locationReminderBodyClient =>
      'Activez la localisation pour recevoir des recommandations de coachs à proximité et voir les distances approximatives. Seule votre ville est publique ; votre adresse reste confidentielle.';

  @override
  String get locationReminderNotNow => 'Pas maintenant';

  @override
  String get locationReminderEnable => 'Activer la localisation';

  @override
  String mealShareServiceMarketingCaption(
      String mealName, int cal, int protein, int carbs, int fat) {
    return '🥗 Je viens de suivre mon repas avec l\'IA SIRVYA !\n🍽️ $mealName\n🔥 $cal kcal · 🥩 ${protein}g Protéines · 🍚 ${carbs}g Glucides · 🥑 ${fat}g Lipides\n\nScannez vos repas, suivez vos macros et atteignez vos objectifs fitness avec les meilleurs coachs sur SIRVYA ! 💪✨\n📲 Téléchargez SIRVYA : https://sirvya.com\n#SIRVYA #Fitness #Nutrition #MealScan #HealthyEating #Coach';
  }

  @override
  String mealShareServiceSubject(String mealName) {
    return 'Suivi avec SIRVYA : $mealName';
  }

  @override
  String get mealShareServiceCopiedFallback =>
      'Résumé du repas copié dans le presse-papiers ! Vous pouvez le coller sur WhatsApp ou Instagram.';

  @override
  String get mealShareServiceCaptionCopied =>
      'Légende du repas et lien SIRVYA copiés dans le presse-papiers !';

  @override
  String get mediaPickerPermissionDenied =>
      'Autorisez l\'accès à l\'appareil photo ou aux photos pour Sirvya dans les réglages de votre téléphone, puis réessayez.';

  @override
  String get mediaPickerOpenPhotoFailed =>
      'Impossible d\'ouvrir cette photo. Veuillez réessayer.';

  @override
  String get notificationNavClientFallback => 'Client';

  @override
  String get notificationNavTitleFallback => 'Notification';

  @override
  String get notificationNavBodyUnavailable =>
      'Cet élément n\'est plus disponible.';

  @override
  String get notificationNavClose => 'Fermer';

  @override
  String get notificationServiceChannelName => 'Notifications Sirvya';

  @override
  String get notificationServiceChannelDesc =>
      'Ce canal est utilisé pour les notifications importantes.';

  @override
  String get appleAuthIosOnly =>
      'La connexion avec Apple est actuellement disponible sur iPhone et iPad.';

  @override
  String get appleAuthFirebaseFailed =>
      'L\'authentification Firebase a échoué.';

  @override
  String get appleAuthIdTokenFailed =>
      'Impossible de récupérer le jeton d\'identification Firebase.';

  @override
  String get appleAuthInvalidResponse => 'Réponse invalide du serveur.';

  @override
  String get appleAuthAccountSuspended => 'Compte suspendu.';

  @override
  String appleAuthSignInError(int statusCode) {
    return 'Erreur de connexion Apple ($statusCode)';
  }

  @override
  String get googleAuthFirebaseFailed =>
      'L\'authentification Firebase a échoué.';

  @override
  String get googleAuthIdTokenFailed =>
      'Impossible de récupérer le jeton d\'identification Firebase.';

  @override
  String get googleAuthInvalidResponse => 'Réponse invalide du serveur.';

  @override
  String get googleAuthAccountSuspended => 'Compte suspendu.';

  @override
  String googleAuthSignInError(int statusCode) {
    return 'Erreur de connexion Google ($statusCode)';
  }

  @override
  String get accountPasswordSheetServerUnreachable =>
      'Impossible de joindre le serveur. Veuillez réessayer.';

  @override
  String accountPasswordSheetEnterField(String label) {
    return 'Saisissez $label';
  }

  @override
  String get accountPasswordSheetMinLength => 'Utilisez au moins 8 caractères.';

  @override
  String get accountPasswordSheetPasswordsMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get accountPasswordSheetShowPassword => 'Afficher le mot de passe';

  @override
  String get accountPasswordSheetHidePassword => 'Masquer le mot de passe';

  @override
  String get accountPasswordSheetClose => 'Fermer';

  @override
  String get accountPasswordSheetTitle => 'Sécurisez votre compte';

  @override
  String get accountPasswordSheetSubtitle =>
      'Choisissez un mot de passe d\'au moins 8 caractères que vous n\'utilisez pas ailleurs.';

  @override
  String get accountPasswordSheetCurrentLabel => 'Mot de passe actuel';

  @override
  String get accountPasswordSheetNewLabel => 'Nouveau mot de passe';

  @override
  String get accountPasswordSheetConfirmLabel => 'Confirmer le mot de passe';

  @override
  String get accountPasswordSheetUpdating => 'Mise à jour du mot de passe…';

  @override
  String get accountPasswordSheetUpdate => 'Mettre à jour le mot de passe';

  @override
  String get appUpdatePromptLinkNotConfigured =>
      'Le lien de mise à jour n\'est pas encore configuré. Veuillez contacter le support Sirvya.';

  @override
  String get appUpdatePromptStoreOpenFailed =>
      'Impossible d\'ouvrir la boutique d\'applications. Veuillez réessayer ou rechercher la mise à jour dans votre boutique.';

  @override
  String get appUpdatePromptUpdateRequiredBadge => 'MISE À JOUR REQUISE';

  @override
  String get appUpdatePromptNewVersionBadge => 'NOUVELLE VERSION';

  @override
  String get appUpdatePromptMandatoryTitle =>
      'Mettez à jour Sirvya pour continuer';

  @override
  String get appUpdatePromptOptionalTitle => 'Une nouvelle version de Sirvya';

  @override
  String get appUpdatePromptMandatoryBody =>
      'Cette version n\'est plus prise en charge. Installez la dernière version pour continuer à utiliser l\'application.';

  @override
  String get appUpdatePromptOptionalBody =>
      'La dernière version est prête. Mettez à jour maintenant pour profiter des dernières améliorations.';

  @override
  String appUpdatePromptInstalledVersion(String version) {
    return 'Installée : $version';
  }

  @override
  String appUpdatePromptMinimumVersion(String version) {
    return 'Minimale : $version';
  }

  @override
  String get appUpdatePromptOpeningStore => 'Ouverture de la boutique…';

  @override
  String get appUpdatePromptUpdateNow => 'Mettre à jour maintenant';

  @override
  String get appUpdatePromptChecking => 'Vérification…';

  @override
  String get appUpdatePromptCheckAgain => 'Vérifier à nouveau';

  @override
  String get appUpdatePromptLater => 'Plus tard';

  @override
  String get campaignDialogExploreNow => 'Découvrir maintenant';

  @override
  String get campaignDialogGotIt => 'Compris';

  @override
  String get campaignDialogBrandHeader => 'SIRVYA  /  INSIDE';

  @override
  String get campaignDialogCloseTooltip => 'Fermer l\'annonce';

  @override
  String get campaignDialogSelectedForYou => 'SÉLECTIONNÉ POUR VOUS';

  @override
  String get campaignDialogDefaultTitle => 'Du nouveau chez Sirvya';

  @override
  String get campaignDialogMaybeLater => 'Peut-être plus tard';

  @override
  String get clientProfileViewPhotoLabel => 'Voir la photo de profil';

  @override
  String get clientProfileChangePhotoTooltip => 'Changer la photo de profil';

  @override
  String get clientProfilePremiumBadge => 'SIRVYA PREMIUM';

  @override
  String get clientProfileJourneyBadge => 'VOTRE PARCOURS SIRVYA';

  @override
  String get clientProfileWelcomeTitle => 'Bienvenue sur Sirvya';

  @override
  String get clientProfileSetCity => 'Définir votre ville';

  @override
  String get clientProfilePersonalSpaceNote =>
      'Votre espace personnel. Conçu autour de vos progrès.';

  @override
  String get clientProfileCompletionTitle => 'Personnalisez votre profil';

  @override
  String clientProfileCompletionDetailsAdded(int completed, int total) {
    return 'Profil complété · $completed sur $total informations ajoutées';
  }

  @override
  String get clientProfileCompletionSemantic => 'Complétion du profil';

  @override
  String get clientProfileStepPhoto => 'Ajouter votre photo de profil';

  @override
  String get clientProfileStepFirstName => 'Ajouter votre prénom';

  @override
  String get clientProfileStepLastName => 'Ajouter votre nom';

  @override
  String get clientProfileStepEmail => 'Ajouter votre adresse e-mail';

  @override
  String get clientProfileStepPhone => 'Ajouter votre numéro de téléphone';

  @override
  String get clientProfileStepCity => 'Définir votre ville';

  @override
  String get clientProfileStepHeight => 'Ajouter votre taille';

  @override
  String get clientProfileStepInterests =>
      'Choisir vos centres d\'intérêt fitness';

  @override
  String get connectionRecoveryCheckTitle => 'Vérifiez votre connexion';

  @override
  String get connectionRecoveryLater => 'Plus tard';

  @override
  String get connectionRecoveryRefreshApp => 'Actualiser l\'application';

  @override
  String get locationPickerFindingCity => 'Recherche de votre ville…';

  @override
  String get locationPickerUseCurrent => 'Utiliser ma position actuelle';

  @override
  String get locationPickerCityLabel => 'Ville';

  @override
  String get locationPickerAddressLabel => 'Adresse détectée (privée)';

  @override
  String get locationPickerPrivacyNotice =>
      'Utilisez le bouton de localisation pour remplir ces champs automatiquement. Seule votre ville est visible par les autres utilisateurs. Votre adresse détaillée et vos coordonnées restent privées.';

  @override
  String get locationPickerKeepUpdatedTitle => 'Maintenir ma position à jour';

  @override
  String get locationPickerKeepUpdatedSubtitle =>
      'Actualiser toutes les 15 minutes. Les mises à jour en arrière-plan nécessitent l\'autorisation « Toujours autoriser ».';

  @override
  String get mealDiaryMoveTitle => 'Déplacer votre repas';

  @override
  String get mealDiarySaveTitle => 'Enregistrer votre repas';

  @override
  String get mealDiaryCancel => 'Annuler';

  @override
  String get mealDiaryMoveSubtitle =>
      'Choisissez son nouvel emplacement dans votre journal.';

  @override
  String get mealDiarySaveSubtitle => 'Où souhaitez-vous ajouter ce repas ?';

  @override
  String get mealDiaryTypeBreakfast => 'Petit-déjeuner';

  @override
  String get mealDiaryTypeLunch => 'Déjeuner';

  @override
  String get mealDiaryTypeDinner => 'Dîner';

  @override
  String get mealDiaryTypeSnack => 'Collation';

  @override
  String mealDiaryMoveTo(String mealType) {
    return 'Déplacer vers $mealType';
  }

  @override
  String mealDiarySaveTo(String mealType) {
    return 'Enregistrer dans $mealType';
  }

  @override
  String get mealDiaryDeleteTitle => 'Supprimer ce repas ?';

  @override
  String mealDiaryDeleteBody(String name) {
    return '« $name » sera retiré de votre journal et de vos totaux quotidiens. Cette action est irréversible.';
  }

  @override
  String get mealDiaryKeepMeal => 'Garder le repas';

  @override
  String get mealDiaryDeleteMeal => 'Supprimer le repas';

  @override
  String get mealLiveCameraNoCamera =>
      'Aucun appareil photo détecté. Choisissez une photo depuis votre galerie.';

  @override
  String get mealLiveCameraPermissionDenied =>
      'Autorisez l\'accès à l\'appareil photo dans les réglages de votre appareil ou navigateur, puis réessayez.';

  @override
  String get mealLiveCameraUnavailable =>
      'Appareil photo indisponible. Réessayez ou choisissez une photo depuis votre galerie.';

  @override
  String get mealLiveCameraCaptureFailed =>
      'Impossible de prendre la photo. Réessayez.';

  @override
  String get mealLiveCameraStarting => 'Démarrage de l\'appareil photo…';

  @override
  String get mealLiveCameraRetry => 'Réessayer l\'appareil photo';

  @override
  String get mealScannerTitle => 'Nutrition Sirvya';

  @override
  String get mealScannerSavedMealsTooltip => 'Repas enregistrés';

  @override
  String get mealScannerDiscoverButton => 'Découvrir votre repas';

  @override
  String get mealScannerFooterDisclaimer =>
      'Photo envoyée pour analyse IA · Les valeurs nutritionnelles sont estimées';

  @override
  String get mealScannerMeetYourMealChip => 'DÉCOUVREZ VOTRE REPAS';

  @override
  String get mealScannerHeading => 'Votre assiette,\ncomprise.';

  @override
  String get mealScannerSubheading =>
      'Un peu de clarté à chaque bouchée.\nDes plats du quotidien aux classiques marocains.';

  @override
  String get mealScannerStepCapture => 'Capturer';

  @override
  String get mealScannerStepReview => 'Vérifier';

  @override
  String get mealScannerStepDiscover => 'Découvrir';

  @override
  String get mealScannerLetsTakeALook => 'Jetons un coup d\'œil';

  @override
  String get mealScannerGoodLightHint =>
      'Bonne lumière. Toute l\'assiette. Une photo.';

  @override
  String get mealScannerKeepWholePlate =>
      'Gardez toute l\'assiette dans le cadre';

  @override
  String get mealScannerPhotoReady => 'Photo prête pour l\'analyse';

  @override
  String get mealScannerAnalyzingTitle => 'Analyse de votre repas en cours';

  @override
  String get mealScannerAnalyzingSubtitle =>
      'Les ingrédients d\'abord. La nutrition ensuite.';

  @override
  String get mealScannerFromGalleryTooltip => 'Depuis la galerie';

  @override
  String get mealScannerGalleryLabel => 'Galerie';

  @override
  String get mealScannerRetakePhoto => 'Reprendre la photo';

  @override
  String get mealScannerCapturePhoto => 'Prendre une photo';

  @override
  String get mealScannerPortionQuestion => 'Quelle quantité mangez-vous ?';

  @override
  String get mealScannerPortionSubtitle =>
      'Choisissez votre portion des aliments sur cette photo.';

  @override
  String get mealScannerPortionHalf => '½ assiette';

  @override
  String get mealScannerPortionOne => '1 assiette';

  @override
  String get mealScannerPortionOneHalf => '1½ assiette';

  @override
  String get mealScannerPortionTwo => '2 assiettes';

  @override
  String get mealScannerNotesLabel => 'Quelque chose d\'invisible ?';

  @override
  String get mealScannerNotesHint =>
      'Supplément d\'huile d\'olive, sauces, sucre…';

  @override
  String get mealScanLimitPausedTitle => 'Les scans de repas sont en pause';

  @override
  String get mealScanLimitReachedTitle =>
      'Vous avez atteint votre limite du jour';

  @override
  String mealScanLimitUsedToday(int used, int total) {
    return '$used / $total scans utilisés aujourd\'hui';
  }

  @override
  String mealScanLimitPerDay(int dailyLimit) {
    String _temp0 = intl.Intl.pluralLogic(
      dailyLimit,
      locale: localeName,
      other: '$dailyLimit scans par jour',
      one: '1 scan par jour',
    );
    return '$_temp0';
  }

  @override
  String mealScanLimitPerDayWithBonus(int dailyLimit, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      dailyLimit,
      locale: localeName,
      other: '$dailyLimit scans par jour',
      one: '1 scan par jour',
    );
    return '$_temp0 + $bonus en bonus aujourd\'hui';
  }

  @override
  String get mealScanLimitPausedBody =>
      'Le scan de repas est actuellement désactivé pour votre compte. Votre administrateur peut mettre à jour votre quota.';

  @override
  String get mealScanLimitReachedBody =>
      'Vous avez atteint votre quota pour aujourd\'hui. Revenez après minuit UTC pour vos prochains scans quotidiens, ou demandez des scans supplémentaires à votre administrateur.';

  @override
  String get mealScanLimitGotIt => 'Compris';

  @override
  String get mealShareCardCalories => 'Calories';

  @override
  String get mealShareCardProtein => 'Protéines';

  @override
  String get mealShareCardCarbs => 'Glucides';

  @override
  String get mealShareCardFat => 'Lipides';

  @override
  String get mealShareModalTitle => 'Partager votre repas';

  @override
  String get mealShareModalSubtitle =>
      'Superposition photo Sirvya pour Stories et Publications';

  @override
  String get mealShareModalClose => 'Fermer';

  @override
  String get mealShareModalStoryTab => 'Story (9:16)';

  @override
  String get mealShareModalPostTab => 'Carte Post';

  @override
  String get mealShareModalStyleOverlay => 'Superposition Sirvya';

  @override
  String get mealShareModalStyleCard => 'Vue Carte';

  @override
  String get mealShareModalIncludeIngredients =>
      'Inclure le détail des ingrédients';

  @override
  String get mealShareModalShareButton => 'Partager Story / Post';

  @override
  String get mealShareModalCopyCaptionButton => 'Copier la légende et le lien';

  @override
  String mealVisualsIngredientIllustration(String name) {
    return 'Illustration de $name';
  }

  @override
  String get mealVisualsAnalysisTitle => 'Analyse du repas';

  @override
  String get mealVisualsShareMealTooltip => 'Partager le repas';

  @override
  String get mealVisualsBackTooltip => 'Retour';

  @override
  String get mealVisualsChipManualDiary => 'VOTRE JOURNAL DE REPAS';

  @override
  String get mealVisualsChipScan => 'SCAN REPAS SIRVYA';

  @override
  String get mealVisualsManualServing => '1 portion · Valeurs saisies';

  @override
  String get mealVisualsEstimatedOnePlate => '1 assiette · Valeurs estimées';

  @override
  String mealVisualsEstimatedPlates(String portion) {
    return '$portion assiettes · Valeurs estimées';
  }

  @override
  String get mealVisualsInsideYourPlate => 'Dans votre assiette';

  @override
  String mealVisualsIngredientsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ingrédients',
      one: '1 ingrédient',
    );
    return '$_temp0';
  }

  @override
  String get mealVisualsFineTunePortions =>
      'Ajustez les portions pour personnaliser cette estimation.';

  @override
  String get mealVisualsAddIngredient => 'Ajouter un ingrédient';

  @override
  String get mealVisualsManualDisclaimer =>
      'Les valeurs nutritionnelles sont basées sur les données que vous avez saisies pour cette portion.';

  @override
  String get mealVisualsScanDisclaimer =>
      'Les images des ingrédients sont des illustrations. Les valeurs nutritionnelles sont estimées à partir de la photo de votre repas et des détails de portion.';

  @override
  String get mealVisualsTotalEnergy => 'ÉNERGIE TOTALE';

  @override
  String get mealVisualsNutritionEntered => 'Valeurs que vous avez saisies';

  @override
  String get mealVisualsEstimateOfPortion => 'Une estimation de cette portion';

  @override
  String get mealVisualsMacroProtein => 'Protéines';

  @override
  String get mealVisualsMacroCarbs => 'Glucides';

  @override
  String get mealVisualsMacroFat => 'Lipides';

  @override
  String get mealVisualsShareToTitle => 'Partager sur';

  @override
  String get mealVisualsShareToSubtitle =>
      'Publiez votre repas et vos macros sur Instagram, WhatsApp et plus';

  @override
  String get mealVisualsChannelStory => 'Story';

  @override
  String get mealVisualsChannelWhatsApp => 'WhatsApp';

  @override
  String get mealVisualsChannelPost => 'Post';

  @override
  String mealVisualsEditIngredientTooltip(String name) {
    return 'Modifier $name';
  }

  @override
  String mealVisualsMoreOptionsTooltip(String name) {
    return 'Plus d\'options pour $name';
  }

  @override
  String get mealVisualsRemoveIngredient => 'Retirer l\'ingrédient';

  @override
  String get mealVisualsContextTitle => 'Un peu de contexte';

  @override
  String get mealVisualsConfidenceManual => 'Saisi manuellement';

  @override
  String mealVisualsConfidenceLevel(String level) {
    return 'Confiance $level';
  }

  @override
  String get mealVisualsSaveChanges => 'Enregistrer';

  @override
  String get mealVisualsSaveMeal => 'Enregistrer le repas';

  @override
  String get mealVisualsSaveBarFooter =>
      'Journal du compte · Les photos restent sur cet appareil';

  @override
  String get notificationCardCatNutrition => 'VOTRE NUTRITION';

  @override
  String get notificationCardCatPricing => 'TARIFS';

  @override
  String get notificationCardCatMessage => 'MESSAGE';

  @override
  String get notificationCardCatFeedback => 'AVIS';

  @override
  String get notificationCardCatSessions => 'VOS SÉANCES';

  @override
  String get notificationCardCatConnections => 'CONNEXIONS';

  @override
  String get notificationCardCatUpdate => 'ACTUALITÉ SIRVYA';

  @override
  String get notificationCardView => 'Voir';

  @override
  String get notificationCardJustNow => 'À l\'instant';

  @override
  String notificationCardMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String notificationCardHoursAgo(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'il y a $hours heures',
      one: 'il y a 1 heure',
    );
    return '$_temp0';
  }

  @override
  String get notificationCardYesterday => 'Hier';

  @override
  String get notificationInboxTitle => 'Vos dernières actualités';

  @override
  String get notificationInboxAllCaughtUp => 'Vous êtes à jour.';

  @override
  String notificationInboxUnreadCount(int count) {
    return '$count non lue(s) · Continuez sur votre lancée.';
  }

  @override
  String get nutritionGoalCardTitle => 'Mon objectif nutritionnel';

  @override
  String get nutritionGoalCardSetGoal => 'Définir un objectif';

  @override
  String get nutritionGoalCardEdit => 'Modifier';

  @override
  String get nutritionGoalCardLoadFailedRetry =>
      'Impossible de charger votre objectif · Réessayer';

  @override
  String get nutritionGoalCardEmptyPrompt =>
      'Choisissez votre objectif et des rappels optionnels. Commencez par des habitudes équilibrées ou fixez un objectif de poids personnel.';

  @override
  String get nutritionGoalCardPersonalGoal => 'Votre objectif personnel';

  @override
  String get nutritionGoalLabelBalanced => 'Adopter des habitudes équilibrées';

  @override
  String get nutritionGoalLabelLose => 'Perdre du poids progressivement';

  @override
  String get nutritionGoalLabelGain => 'Prendre du poids progressivement';

  @override
  String get nutritionGoalLabelMaintain => 'Maintenir mon poids';

  @override
  String get nutritionGoalCardStatusAchieved =>
      'Objectif atteint · Choisissez un nouvel objectif quand vous êtes prêt(e)';

  @override
  String get nutritionGoalCardStatusPaused =>
      'En pause · Reprenez quand vous le souhaitez';

  @override
  String get nutritionGoalCardStatusActiveRemindersOn =>
      'Actif · Les rappels suivent vos préférences';

  @override
  String get nutritionGoalCardStatusActiveRemindersOff =>
      'Actif · Rappels désactivés';

  @override
  String get nutritionGoalCardAddWeighInHint =>
      'Ajoutez une pesée récente pour suivre votre objectif.';

  @override
  String get nutritionGoalCardBasedOnWeighIns =>
      'Basé sur vos pesées enregistrées. L\'accomplissement repose sur vos suivis récents et non sur une date promise.';

  @override
  String get nutritionGoalCardProgressButton => 'Progrès mensuels et annuels';

  @override
  String get nutritionReviewLoadError =>
      'Impossible de charger ce bilan. Réessayez.';

  @override
  String get nutritionReviewTitle => 'Bilan de vos progrès';

  @override
  String get nutritionReviewMonthly => 'Mensuel';

  @override
  String get nutritionReviewYearly => 'Annuel';

  @override
  String get nutritionReviewPreviousPeriod => 'Période précédente';

  @override
  String get nutritionReviewNextPeriod => 'Période suivante';

  @override
  String nutritionReviewDaysLogged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours enregistrés',
      one: '1 jour enregistré',
    );
    return '$_temp0';
  }

  @override
  String nutritionReviewSavedMeals(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repas enregistrés',
      one: '1 repas enregistré',
    );
    return '$_temp0';
  }

  @override
  String get nutritionReviewDailyAveragesTitle => 'Moyennes quotidiennes';

  @override
  String get nutritionReviewDailyAveragesSubtitle =>
      'Seuls les jours avec des repas enregistrés sont inclus. Les jours non renseignés ne sont pas comptés comme un apport nul.';

  @override
  String get nutritionReviewWeightCheckInsTitle => 'Pesées';

  @override
  String nutritionReviewWeightCheckInsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pesées sur cette période',
      one: '1 pesée sur cette période',
    );
    return '$_temp0';
  }

  @override
  String nutritionReviewWeightRange(String first, String latest) {
    return '$first à $latest kg';
  }

  @override
  String get nutritionReviewFooterDisclaimer =>
      'Il s\'agit de votre historique enregistré et non d\'une mesure exhaustive de vos apports. Des suivis réguliers vous aident à mieux comprendre votre routine.';

  @override
  String get profileCompletedBadgeLabel => 'Profil complété';

  @override
  String get weightProgressHeaderTag => 'VOS PROGRÈS';

  @override
  String get weightProgressHeaderTitle => 'Chaque pesée compte.';

  @override
  String get weightProgressLogTooltip => 'Enregistrer un poids';

  @override
  String get weightProgressRefreshHistory => 'Actualiser l\'historique';

  @override
  String get weightProgressCurrentWeight => 'Poids actuel';

  @override
  String get weightProgressFirstWeighInHint =>
      'Votre première pesée commence ici.';

  @override
  String weightProgressLatestWeighIn(String date) {
    return 'Dernière pesée · $date';
  }

  @override
  String get weightProgressSinceFirst => 'depuis votre première pesée';

  @override
  String get weightProgressStartingWeight => 'Poids de départ';

  @override
  String get weightProgressWeighInsLogged => 'Pesées enregistrées';

  @override
  String get weightProgressTrendTitle => 'Évolution du poids';

  @override
  String get weightProgressTrendSubtitle => 'Un aperçu de votre parcours.';

  @override
  String get weightProgressPeriod7Days => '7 jours';

  @override
  String get weightProgressPeriod30Days => '30 jours';

  @override
  String get weightProgressPeriodRecent => 'Récent';

  @override
  String weightProgressChartSemantics(int count, String weight, String date) {
    return 'Évolution du poids, $count pesées. Sélectionné : $weight kilogrammes le $date.';
  }

  @override
  String get weightProgressChartSinglePointHint =>
      'Votre premier point est sur le graphique. Ajoutez-en un autre pour voir une tendance. Dates en UTC.';

  @override
  String get weightProgressChartMultiPointHint =>
      'Appuyez ou glissez sur le graphique pour explorer vos pesées. Dates en UTC.';

  @override
  String get weightProgressEmptyStoryTitle =>
      'Votre histoire commence par une pesée.';

  @override
  String get weightProgressEmptyPeriodTitle =>
      'Aucune pesée sur cette période.';

  @override
  String get weightProgressEmptyStorySubtitle =>
      'Enregistrez un poids pour démarrer votre suivi personnel.';

  @override
  String get weightProgressEmptyPeriodSubtitle =>
      'Choisissez Récent pour voir vos derniers enregistrements disponibles.';

  @override
  String get weightProgressRecentTitle => 'Pesées récentes';

  @override
  String weightProgressInViewCount(int count) {
    return '$count affichée(s)';
  }

  @override
  String get weightProgressEmptyRecords =>
      'Vos poids enregistrés apparaîtront ici.';

  @override
  String get weightProgressFirstInView => 'Première de cette vue';

  @override
  String weightProgressChangeFromPrevious(String change) {
    return '$change par rapport à la précédente';
  }

  @override
  String get weightProgressChartLimitFooter =>
      'Graphique : jusqu\'aux 90 dernières pesées enregistrées. Liste : les 5 dernières de cette vue.';

  @override
  String get weightProgressKeepRecordTitle =>
      'Gardez une trace, à votre rythme.';

  @override
  String get weightProgressKeepRecordSubtitle =>
      'Un suivi rapide ajoute une nouvelle étape à votre parcours.';

  @override
  String get weightProgressLogButton => 'Enregistrer une pesée';

  @override
  String weightProgressBmiLabel(String bmi) {
    return 'IMC · $bmi';
  }

  @override
  String get weightProgressBmiSubtitle =>
      'Calculé à partir de votre dernier poids et de votre taille enregistrée.';

  @override
  String get weightLogInvalidError =>
      'Saisissez un poids valide compris entre 0 et 500 kg.';

  @override
  String get weightLogSaveError =>
      'Impossible d\'enregistrer. Votre saisie est conservée — veuillez réessayer.';

  @override
  String get weightLogSheetTitle => 'Un moment pour vous.';

  @override
  String get weightLogCloseTooltip => 'Fermer';

  @override
  String get weightLogSheetSubtitle =>
      'Enregistrez votre poids et gardez un œil sur votre parcours.';

  @override
  String get weightLogInputLabel => 'Poids (kg)';

  @override
  String get weightLogRecordedTodayHint =>
      'Enregistré pour aujourd\'hui. Vous pouvez utiliser un point ou une virgule.';

  @override
  String weightLogLastRecordedHint(String weight) {
    return 'Dernier enregistrement : $weight kg · Enregistré pour aujourd\'hui.';
  }

  @override
  String get weightLogSaving => 'Enregistrement…';

  @override
  String get weightLogSaveButton => 'Enregistrer la pesée';

  @override
  String get announcementClose => 'Fermer';

  @override
  String get announcementWhatsNewTitle => 'Quoi de neuf chez Sirvya';

  @override
  String get announcementDismissTooltip => 'Masquer les annonces';

  @override
  String get announcementSirvyaUpdate => 'ACTUALITÉ SIRVYA';

  @override
  String get announcementExploreCoaches => 'Explorer les coachs';

  @override
  String get announcementLearnMore => 'En savoir plus';

  @override
  String get announcementReadMore => 'Lire la suite';

  @override
  String chatImageBatchSendPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoyer $count photos',
      one: 'Envoyer 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get chatImageBatchCaptionHint =>
      'Légende pour la première photo (optionnel)';

  @override
  String get chatImageBatchCancel => 'Annuler';

  @override
  String chatSelectionSelectedCount(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get chatSelectionSelectAllTooltip =>
      'Sélectionner tous les messages chargés';

  @override
  String get chatSelectionDeleteTooltip => 'Supprimer les messages';

  @override
  String get clientNavHome => 'Accueil';

  @override
  String get clientNavExplore => 'Explorer';

  @override
  String get clientNavSessions => 'Séances';

  @override
  String get clientNavProfile => 'Profil';

  @override
  String get clientNavScanMealLabel => 'Scanner votre repas';

  @override
  String coachHeaderNotificationsUnread(int count) {
    return 'Notifications, $count non lue(s)';
  }

  @override
  String get coachHeaderNotifications => 'Notifications';

  @override
  String get coachHeaderOpenProfileLabel => 'Ouvrir le profil du coach';

  @override
  String get coachNavbarDashboard => 'Tableau de bord';

  @override
  String get coachNavbarCalendar => 'Calendrier';

  @override
  String get coachNavbarChats => 'Messagerie';

  @override
  String get coachNavbarClients => 'Clients';

  @override
  String get coachNavbarProfile => 'Profil';

  @override
  String conversationSendingPhotoBatch(int current, int total) {
    return 'Envoi de la photo $current sur $total…';
  }

  @override
  String get conversationSendingAttachment => 'Envoi de votre pièce jointe…';

  @override
  String get conversationSendingMessage => 'Envoi du message…';

  @override
  String get conversationRefreshError =>
      'Impossible d\'actualiser. Vos messages sont toujours là.';

  @override
  String get conversationRetry => 'Réessayer';

  @override
  String conversationNewUnread(int count) {
    return '$count nouveau(x)';
  }

  @override
  String get conversationBackTooltip => 'Retour';

  @override
  String get conversationStorageNotice =>
      'Les photos et messages vocaux restent sur cet appareil';

  @override
  String get conversationDismissNoticeTooltip => 'Masquer l\'avis de stockage';

  @override
  String get conversationLoading => 'Chargement de la conversation…';

  @override
  String get conversationEmptyTitle => 'Démarrez la conversation';

  @override
  String get conversationEmptySubtitle =>
      'Un simple bonjour suffit pour commencer.';

  @override
  String get conversationRetryOlder =>
      'Réessayer de charger les anciens messages';

  @override
  String get conversationDayToday => 'Aujourd\'hui';

  @override
  String get conversationDayYesterday => 'Hier';

  @override
  String get conversationDeletedByYou => 'Vous avez supprimé ce message';

  @override
  String get conversationDeletedByOther => 'Ce message a été supprimé';

  @override
  String get conversationAttachPhotosTooltip => 'Joindre des photos';

  @override
  String conversationRecordingTimer(String time) {
    return 'Enregistrement $time';
  }

  @override
  String get conversationWriteMessageHint => 'Écrire un message…';

  @override
  String get conversationPhotoGalleryTooltip => 'Galerie photos';

  @override
  String get conversationStopRecordingSendTooltip =>
      'Arrêter l\'enregistrement et envoyer';

  @override
  String get conversationSendMessageTooltip => 'Envoyer le message';

  @override
  String get conversationRecordVoiceTooltip => 'Enregistrer un message vocal';

  @override
  String get exploreCoachGridRemoveFavorite => 'Retirer des favoris';

  @override
  String get exploreCoachGridAddFavorite => 'Ajouter aux favoris';

  @override
  String get exploreCoachGridNew => 'Nouveau';

  @override
  String exploreCoachGridFromPrice(int price) {
    return 'À partir de $price MAD';
  }

  @override
  String get exploreCoachGridPriceOnRequest => 'Prix sur demande';

  @override
  String get exploreCoachGridViewAndBook => 'Voir et réserver';

  @override
  String get exploreCoachMapLoadError =>
      'Impossible de charger la carte. Veuillez réessayer.';

  @override
  String get exploreCoachMapCoachesInArea => 'Coachs dans cette zone';

  @override
  String get exploreCoachMapViewAndBook => 'Voir et réserver';

  @override
  String get exploreCoachMapRetry => 'Réessayer';

  @override
  String get exploreCoachMapYourLocation => 'Votre position';

  @override
  String exploreCoachMapCoachesInAreaSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coachs dans cette zone',
      one: '1 coach dans cette zone',
    );
    return '$_temp0';
  }

  @override
  String get exploreCoachMapOsmCopyright => '© Contributeurs OpenStreetMap';

  @override
  String get exploreCoachMapTilesUnavailable =>
      'Tuiles de carte indisponibles. Vérifiez votre connexion.';

  @override
  String get exploreCoachMapNoCoachesMatch =>
      'Aucun coach avec une position enregistrée ne correspond à vos filtres.';

  @override
  String exploreCoachMapApproximateLocations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count coachs · Positions approximatives',
      one: '1 coach · Position approximative',
    );
    return '$_temp0';
  }

  @override
  String get exploreCoachMapSetYourLocation => 'Définir votre position';

  @override
  String get exploreCoachMapNearMe => 'Autour de moi';

  @override
  String get exploreCoachMapShowAllCoaches => 'Afficher tous les coachs';

  @override
  String get exploreCoachMapRefreshMap => 'Actualiser la carte';

  @override
  String get exploreCoachMapZoomOut => 'Dézoomer';

  @override
  String get exploreCoachMapZoomIn => 'Zoomer';

  @override
  String get localChatMediaDeleteTitle => 'Supprimer de ce téléphone ?';

  @override
  String get localChatMediaDeleteBody =>
      'Le message reste dans votre historique. Une fois la copie du serveur supprimée, ce fichier ne pourra plus être téléchargé.';

  @override
  String get localChatMediaCancel => 'Annuler';

  @override
  String get localChatMediaDeleteFile => 'Supprimer le fichier';

  @override
  String get localChatMediaMissingError =>
      'Ce fichier était stocké sur l\'appareil d\'origine. La suppression de l\'application efface les photos et messages vocaux locaux. Demandez à l\'expéditeur de le renvoyer.';

  @override
  String get localChatMediaNotOnDevice => 'Absent de cet appareil';

  @override
  String get localChatMediaSending => 'Envoi…';

  @override
  String get localChatMediaRetryDownload => 'Réessayer le téléchargement';

  @override
  String get localChatMediaDownloading => 'Téléchargement…';

  @override
  String get localChatMediaLoadingPhoto => 'Chargement de la photo…';

  @override
  String get managerHeaderRoleBadge => 'MANAGER';

  @override
  String get managerNavbarDashboard => 'Tableau de bord';

  @override
  String get managerNavbarClients => 'Clients';

  @override
  String get managerNavbarCoaches => 'Coachs';

  @override
  String get managerNavbarReservations => 'Réservations';

  @override
  String get managerNavbarMore => 'Plus';

  @override
  String get voiceNoteTapToRetry => 'Appuyez pour réessayer';

  @override
  String get voiceNoteLoadingTooltip => 'Chargement du message vocal';

  @override
  String get voiceNoteRetryTooltip => 'Réessayer le message vocal';

  @override
  String get voiceNotePauseTooltip => 'Mettre en pause le message vocal';

  @override
  String get voiceNotePlayTooltip => 'Lire le message vocal';

  @override
  String get voiceNoteSeekBarLabel => 'Barre de progression du message vocal';

  @override
  String voiceNoteSeekBarValue(int percent) {
    return '$percent pour cent';
  }

  @override
  String get voiceNoteLoading => 'Chargement…';

  @override
  String get voiceNoteLabel => 'Message vocal';

  @override
  String get blockedUsersListLoadFailed =>
      'Impossible de charger les utilisateurs bloqués';

  @override
  String blockedUsersListNetworkError(String error) {
    return 'Erreur réseau : $error';
  }

  @override
  String blockedUsersListUnblockTitle(String name) {
    return 'Débloquer $name ?';
  }

  @override
  String get blockedUsersListUnblockMessage =>
      'Cette personne pourra de nouveau voir votre profil et vous envoyer des messages.';

  @override
  String get blockedUsersListCancel => 'Annuler';

  @override
  String get blockedUsersListUnblock => 'Débloquer';

  @override
  String blockedUsersListUnblocked(String name) {
    return '$name a été débloqué(e)';
  }

  @override
  String get blockedUsersListUnblockFailed =>
      'Impossible de débloquer l\'utilisateur';

  @override
  String get blockedUsersListTitle => 'Utilisateurs bloqués';

  @override
  String get blockedUsersListRetry => 'Réessayer';

  @override
  String get blockedUsersListEmptyTitle => 'Aucun utilisateur bloqué';

  @override
  String get blockedUsersListEmptyMessage =>
      'Lorsque vous bloquez quelqu’un, il apparaîtra ici.';

  @override
  String get blockedUsersListBlockedLabel => 'Bloqué';

  @override
  String get clientNotificationsLoadFailed =>
      'Impossible de charger les notifications';

  @override
  String get clientNotificationsMarkReadFailed =>
      'Impossible de marquer les notifications comme lues.';

  @override
  String get clientNotificationsTitle => 'Notifications';

  @override
  String get clientNotificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String clientNotificationsErrorRetry(String error) {
    return '$error · Réessayer';
  }

  @override
  String get clientNotificationsEmpty => 'Aucune notification pour le moment.';

  @override
  String coachInvitationsMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String coachInvitationsHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String get coachInvitationsYesterday => 'Hier';

  @override
  String coachInvitationsDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'il y a $days jours',
      one: 'il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get coachInvitationsGenericError =>
      'Une erreur est survenue, veuillez réessayer.';

  @override
  String get coachInvitationsEmpty =>
      'Aucune invitation n\'a encore été ouverte';

  @override
  String get coachInvitationsTitle => 'Invitations';

  @override
  String get coachInvitationsPointsHeader => 'Points d\'invitation de clients';

  @override
  String coachInvitationsPointsValue(int points) {
    return '$points pts';
  }

  @override
  String get coachInvitationsAcceptedClients => 'clients acceptés';

  @override
  String coachInvitationsPointsEarned(int points) {
    return '+$points pts';
  }

  @override
  String get coachInvitationsDeclined => 'Refusée';

  @override
  String get coachInvitationsDecline => 'Refuser';

  @override
  String get coachInvitationsAccept => 'Accepter';

  @override
  String get welcomePage1Tag => 'COACHING';

  @override
  String get welcomePage1Title => 'Votre coach,';

  @override
  String get welcomePage1Accent => 'à la demande.';

  @override
  String get welcomePage1Subtitle =>
      'Trouvez des coachs certifiés près de chez vous et réservez une séance en quelques secondes.';

  @override
  String get welcomePage2Tag => 'PROGRÈS';

  @override
  String get welcomePage2Title => 'Suivez chaque';

  @override
  String get welcomePage2Accent => 'étape.';

  @override
  String get welcomePage2Subtitle =>
      'Suivez vos séances et mesurez vos progrès jour après jour.';

  @override
  String get welcomePage3Tag => 'COMMUNAUTÉ';

  @override
  String get welcomePage3Title => 'Rejoignez';

  @override
  String get welcomePage3Accent => 'SIRVYA.';

  @override
  String get welcomePage3Subtitle =>
      'Entrez en contact avec les meilleurs coachs et transformez durablement votre corps.';

  @override
  String get welcomeSkip => 'Passer';

  @override
  String get welcomeLogIn => 'SE CONNECTER';

  @override
  String get welcomeCreateAccount => 'CRÉER UN COMPTE';

  @override
  String get coachInviteClientsLoadError =>
      'Impossible de charger les invitations. Veuillez réessayer.';

  @override
  String get coachInviteClientsCopied => 'Copié dans le presse-papiers';

  @override
  String get coachInviteClientsShareTitle => 'Rejoignez-moi sur SIRVYA';

  @override
  String coachInviteClientsShareText(String link, String code) {
    return 'Vous êtes invité(e) à me rejoindre sur SIRVYA. Trouvez votre coach ou développez votre activité de coaching.\n\n$link\n\nCode d’invitation : $code';
  }

  @override
  String coachInviteClientsShareFallback(String link, String code) {
    return 'Rejoignez-moi sur SIRVYA : $link\nCode d’invitation : $code';
  }

  @override
  String get coachInviteClientsTitle => 'Inviter et grandir';

  @override
  String get coachInviteClientsRetry => 'Réessayer';

  @override
  String get coachInviteClientsHeading => 'Développez votre réseau SIRVYA';

  @override
  String get coachInviteClientsIntro =>
      'Un seul code pour les clients et les coachs. Suivez les personnes qui s’inscrivent avec succès grâce à votre invitation.';

  @override
  String get coachInviteClientsYourCode => 'Votre code d’invitation';

  @override
  String get coachInviteClientsCopyCode => 'Copier le code';

  @override
  String get coachInviteClientsCopyLink => 'Copier le lien';

  @override
  String get coachInviteClientsShare => 'Partager';

  @override
  String get coachInviteClientsClientsJoined => 'Clients inscrits';

  @override
  String get coachInviteClientsCoachesJoined => 'Coachs inscrits';

  @override
  String coachInviteClientsPoints(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points',
      one: '1 point',
      zero: '0 point',
    );
    return '$_temp0';
  }

  @override
  String get coachInviteClientsRewardBalance =>
      'Votre solde total de récompenses';

  @override
  String get coachInviteClientsHowRewards => 'Fonctionnement des récompenses';

  @override
  String get coachInviteClientsRewardRules =>
      'Coach : 40 points après la création d’un nouveau compte.\nClient : 20 points lorsque vous acceptez sa connexion dans Clients. Partager ou ouvrir un lien ne rapporte pas de points.';

  @override
  String get coachInviteClientsPeopleInvited =>
      'Personnes que vous avez invitées';

  @override
  String get coachInviteClientsFilterAll => 'Tous';

  @override
  String get coachInviteClientsFilterClients => 'Clients';

  @override
  String get coachInviteClientsFilterCoaches => 'Coachs';

  @override
  String get coachInviteClientsEmpty =>
      'Aucune inscription dans cette catégorie pour le moment. Partagez votre lien pour commencer.';

  @override
  String get coachInviteClientsRoleCoach => 'Coach';

  @override
  String get coachInviteClientsRoleClient => 'Client';

  @override
  String get coachInviteClientsStatusPending => 'Connexion en attente';

  @override
  String get coachInviteClientsStatusConnected => 'Connecté';

  @override
  String get coachInviteClientsStatusDeclined => 'Connexion refusée';

  @override
  String get coachInviteClientsStatusRegistered => 'Inscrit';

  @override
  String coachInviteClientsRoleStatus(String role, String status) {
    return '$role • $status';
  }

  @override
  String coachInviteClientsPointsAwarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '+$count pt$_temp0';
  }

  @override
  String get coachClientsInviteAccepted =>
      'Invitation acceptée : +20 points. Le client est maintenant disponible dans les discussions.';

  @override
  String get coachClientsInviteDeclined => 'Invitation refusée.';

  @override
  String get coachClientsInviteUpdateFailed =>
      'Impossible de mettre à jour l’invitation.';

  @override
  String get coachClientsYourClients => 'VOS CLIENTS';

  @override
  String get coachClientsTitle => 'Mes clients';

  @override
  String get coachClientsLoading => 'Chargement…';

  @override
  String get coachClientsEmptySubtitle =>
      'Les réservations et les invitations amènent vos clients ici';

  @override
  String coachClientsCountSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clients • Séances et conversations',
      one: '1 client • Séances et conversations',
    );
    return '$_temp0';
  }

  @override
  String get coachClientsInvite => 'Inviter';

  @override
  String get coachClientsStatTotal => 'Total';

  @override
  String get coachClientsStatPending => 'En attente';

  @override
  String get coachClientsStatUpcoming => 'À venir';

  @override
  String get coachClientsFilterAll => 'Tous';

  @override
  String get coachClientsSearchHint => 'Rechercher des clients...';

  @override
  String get coachClientsSort => 'Trier';

  @override
  String get coachClientsSortAz => 'Nom A–Z';

  @override
  String get coachClientsSortZa => 'Nom Z–A';

  @override
  String get coachClientsSortNewest => 'Dernières connexions';

  @override
  String get coachClientsInvitations => 'INVITATIONS DE CLIENTS';

  @override
  String coachClientsPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count en attente',
      one: '1 en attente',
    );
    return '$_temp0';
  }

  @override
  String get coachClientsClientFallback => 'Client';

  @override
  String get coachClientsStatusPending => 'En attente';

  @override
  String coachClientsStatusAccepted(String points) {
    return 'Acceptée · +$points pts';
  }

  @override
  String get coachClientsStatusDeclined => 'Refusée';

  @override
  String get coachClientsDecline => 'Refuser';

  @override
  String get coachClientsAccept => 'Accepter';

  @override
  String get coachClientsJustNow => 'À l’instant';

  @override
  String coachClientsMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String coachClientsHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String coachClientsDaysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get coachClientsEmptyTitle =>
      'Vos clients de coaching apparaîtront ici';

  @override
  String get coachClientsEmptyBody =>
      'Les clients apparaissent lorsqu’ils réservent avec vous ou lorsque vous acceptez leur invitation.';

  @override
  String get coachClientsUpcomingSession => 'Séance à venir';

  @override
  String coachClientsNextSession(String date, String time) {
    return 'Prochaine : $date à $time';
  }

  @override
  String coachClientsSessionSummary(int sessions, int upcoming, int pending) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions séances',
      one: '1 séance',
    );
    return '$_temp0 • $upcoming à venir • $pending en attente';
  }

  @override
  String get coachClientsLoadError => 'Impossible de charger les clients';

  @override
  String get coachClientsRetry => 'Réessayer';

  @override
  String get coachClientsNoMatchSearch =>
      'Aucun client ne correspond à votre recherche.';

  @override
  String get coachClientsNoMatchFilter =>
      'Aucun client ne correspond à ce filtre.';

  @override
  String get clientChangeEmailInvalidEmail =>
      'Veuillez saisir une adresse e-mail valide.';

  @override
  String get clientChangeEmailInvalidCode =>
      'Veuillez saisir le code de vérification à 6 chiffres.';

  @override
  String get clientChangeEmailVerifyFailed =>
      'La vérification a échoué. Veuillez réessayer.';

  @override
  String get clientChangeEmailCodeSent =>
      'Un nouveau code de vérification a été envoyé.';

  @override
  String get clientChangeEmailTitle => 'Modifier l’adresse e-mail';

  @override
  String clientChangeEmailStepOf(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get clientChangeEmailHeadingNew =>
      'Saisissez votre nouvelle adresse e-mail';

  @override
  String get clientChangeEmailHeadingVerifyCurrent =>
      'Vérifiez votre adresse e-mail actuelle';

  @override
  String get clientChangeEmailHeadingVerifyNew =>
      'Confirmez votre nouvelle adresse e-mail';

  @override
  String clientChangeEmailIntroStart(String email) {
    return 'Nous enverrons d’abord un code de vérification à votre adresse e-mail actuelle ($email).';
  }

  @override
  String clientChangeEmailIntroCode(String email) {
    return 'Saisissez le code à 6 chiffres envoyé à $email.';
  }

  @override
  String get clientChangeEmailNewEmailLabel => 'Nouvelle adresse e-mail';

  @override
  String get clientChangeEmailCodeLabel => 'Code de vérification à 6 chiffres';

  @override
  String get clientChangeEmailPleaseWait => 'Veuillez patienter…';

  @override
  String get clientChangeEmailSendCodeButton =>
      'Envoyer le code de vérification';

  @override
  String get clientChangeEmailVerifySendButton =>
      'Vérifier et envoyer à la nouvelle adresse';

  @override
  String get clientChangeEmailConfirmButton =>
      'Confirmer le changement d’e-mail';

  @override
  String get clientChangeEmailResend => 'Renvoyer le code';

  @override
  String get clientChangeEmailStartAgain => 'Recommencer';

  @override
  String get clientConversationListUnknown => 'Inconnu';

  @override
  String clientConversationListError(int code) {
    return 'Erreur ($code)';
  }

  @override
  String get clientConversationListServerUnreachable =>
      'Impossible de joindre le serveur. Vérifiez votre connexion.';

  @override
  String get clientConversationListTitle => 'Messagerie';

  @override
  String get clientConversationListSubtitle => 'Discutez avec vos coachs';

  @override
  String get clientConversationListFilterAll => 'Tous';

  @override
  String get clientConversationListFilterUnread => 'Non lus';

  @override
  String get clientConversationListSearchHint =>
      'Rechercher une conversation...';

  @override
  String get clientConversationListRetry => 'RÉESSAYER';

  @override
  String get clientConversationListEmptyTitle => 'Aucune conversation';

  @override
  String get clientConversationListEmptySubtitle =>
      'Vos échanges avec les coachs apparaîtront ici.';

  @override
  String clientConversationListNoResults(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get clientConversationListFooter =>
      'Vos messages personnels restent privés et sécurisés';

  @override
  String get clientConversationListTapToOpen =>
      'Appuyez pour ouvrir la conversation';

  @override
  String get clientConversationListYesterday => 'Hier';

  @override
  String get clientQrScannerPrompt =>
      'Placez le QR code du coach dans le cadre';

  @override
  String get coachChangeEmailTitle => 'Modifier l’adresse e-mail';

  @override
  String get coachChangeEmailLoadRetry =>
      'Impossible de charger l’adresse e-mail. Appuyez pour réessayer.';

  @override
  String get coachConversationsYesterday => 'Hier';

  @override
  String get coachConversationsEmpty => 'Aucune conversation pour le moment';

  @override
  String get coachConversationsFooter =>
      'Vos échanges avec vos clients sont privés et sécurisés';

  @override
  String get coachConversationsTitle => 'Messagerie';

  @override
  String get coachConversationsSubtitle => 'Conversations avec vos clients';

  @override
  String get coachConversationsFilterAll => 'Tous';

  @override
  String get coachConversationsFilterUnread => 'Non lus';

  @override
  String get coachConversationsSearchHint => 'Rechercher un client...';

  @override
  String get coachConversationsTapToOpen =>
      'Appuyez pour ouvrir la conversation';

  @override
  String get coachVisibilityUpdateFailed =>
      'Impossible de mettre à jour les paramètres de visibilité.';

  @override
  String get coachVisibilityNetworkError =>
      'Erreur réseau. Veuillez réessayer.';

  @override
  String get coachVisibilityTitle => 'Visibilité du profil';

  @override
  String get coachVisibilitySave => 'Enregistrer';

  @override
  String get coachVisibilityProfileSection => 'Recherche et découverte';

  @override
  String get coachVisibilityProfileDesc =>
      'Contrôlez si les clients peuvent trouver votre profil dans les résultats de recherche et les recommandations.';

  @override
  String get coachVisibilityPublicProfile => 'Profil public';

  @override
  String get coachVisibilityPublicProfileDesc =>
      'Permettre aux clients de découvrir et consulter votre profil';

  @override
  String get coachVisibilityMessagingSection => 'Préférences de messagerie';

  @override
  String get coachVisibilityMessagingDesc =>
      'Choisissez qui peut démarrer directement une conversation avec vous.';

  @override
  String get coachVisibilityDirectMessaging => 'Messagerie directe';

  @override
  String get coachVisibilityDirectMessagingDesc =>
      'Autoriser les clients à vous écrire avant de réserver';

  @override
  String get coachChangePhoneErrorMissing =>
      'Veuillez saisir l’indicatif pays et le numéro de téléphone.';

  @override
  String get coachChangePhoneErrorFailed =>
      'Impossible de mettre à jour le numéro de téléphone.';

  @override
  String get coachChangePhoneErrorServer =>
      'Erreur serveur. Veuillez vérifier votre connexion.';

  @override
  String get coachChangePhoneTitle => 'Numéro de téléphone';

  @override
  String get coachChangePhoneSubtitle =>
      'Mettez à jour le numéro de téléphone associé à votre compte.';

  @override
  String get coachChangePhoneSave => 'Enregistrer le numéro';

  @override
  String get splashTagline => 'VOTRE PARCOURS FITNESS';

  @override
  String get mainLayoutNavHome => 'Accueil';

  @override
  String get mainLayoutNavExplore => 'Explorer';

  @override
  String get mainLayoutNavSessions => 'Séances';

  @override
  String get mainLayoutNavProfile => 'Profil';

  @override
  String mainLayoutPlaceholderItem(String title, int index) {
    return '$title — Élément n°$index';
  }

  @override
  String get mainLayoutPlaceholderHint => 'Écran en cours de construction';

  @override
  String get userLocationSettingsDetectPrompt =>
      'Veuillez d’abord détecter ou sélectionner une ville et des coordonnées.';

  @override
  String get userLocationSettingsTitle => 'Ma position';

  @override
  String get userLocationSettingsLoadError =>
      'Impossible de charger votre position enregistrée.';

  @override
  String get userLocationSettingsBackgroundTitle =>
      'Autorisation de localisation en arrière-plan';

  @override
  String get userLocationSettingsBackgroundSubtitle =>
      'Gérer l’accès à la position dans les paramètres système';

  @override
  String get userLocationSettingsSaving => 'Enregistrement…';

  @override
  String get userLocationSettingsContinue => 'Continuer';

  @override
  String get userLocationSettingsSave => 'Enregistrer la position';

  @override
  String get coachChangePasswordAllRequired =>
      'Tous les champs sont obligatoires.';

  @override
  String get coachChangePasswordMismatch =>
      'Les nouveaux mots de passe ne correspondent pas.';

  @override
  String get coachChangePasswordTooShort =>
      'Le nouveau mot de passe doit comporter au moins 8 caractères.';

  @override
  String get coachChangePasswordFailed =>
      'Échec de la mise à jour du mot de passe.';

  @override
  String get coachChangePasswordServerError =>
      'Erreur du serveur. Veuillez vérifier votre connexion.';

  @override
  String get coachChangePasswordTitle => 'Mot de passe et sécurité';

  @override
  String get coachChangePasswordSubtitle =>
      'Modifiez le mot de passe de votre compte.';

  @override
  String get coachChangePasswordCurrent => 'Mot de passe actuel';

  @override
  String get coachChangePasswordNew => 'Nouveau mot de passe';

  @override
  String get coachChangePasswordConfirm => 'Confirmer le nouveau mot de passe';

  @override
  String get coachChangePasswordUpdate => 'Mettre à jour le mot de passe';

  @override
  String get coachNotificationsUpdateFailed =>
      'Impossible de mettre à jour les notifications';

  @override
  String get coachNotificationsTitle => 'Notifications';

  @override
  String get coachNotificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get coachNotificationsLoadError =>
      'Impossible de charger les notifications';

  @override
  String get coachNotificationsRetry => 'Réessayer';

  @override
  String get coachNotificationsEmptyTitle =>
      'Aucune notification pour le moment.';

  @override
  String get coachNotificationsEmptyBody =>
      'Les messages, les réservations et les rappels de séance apparaîtront ici.';

  @override
  String get accountSecurityPasswordUpdateFailed =>
      'Impossible de mettre à jour votre mot de passe. Veuillez réessayer.';

  @override
  String get apiServiceNetworkError =>
      'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get connectionRecoveryMessage =>
      'Votre connexion est peut-être faible ou interrompue, ou le serveur est temporairement indisponible. Vérifiez votre Wi-Fi ou vos données mobiles, puis réessayez.';

  @override
  String get conversationActivityTyping => 'Écrit…';

  @override
  String get conversationActivityRecording => 'Enregistre un message vocal…';

  @override
  String socialAuthNotAvailable(String provider) {
    return 'La connexion avec $provider n\'est pas encore disponible. Veuillez utiliser votre e-mail et votre mot de passe.';
  }

  @override
  String get socialAuthAccountExists =>
      'Un compte existe déjà avec cet e-mail. Connectez-vous avec votre méthode d\'origine.';

  @override
  String get socialAuthNetwork =>
      'Vérifiez votre connexion Internet et réessayez.';

  @override
  String socialAuthNotVerified(String provider) {
    return 'La connexion avec $provider n\'a pas pu être vérifiée. Veuillez réessayer.';
  }

  @override
  String get socialAuthUserDisabled =>
      'Ce compte est indisponible. Veuillez contacter le support.';

  @override
  String socialAuthFailed(String provider) {
    return 'La connexion avec $provider a échoué. Veuillez réessayer.';
  }
}
