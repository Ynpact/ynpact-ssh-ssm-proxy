# A propos de la sécurité

## Clé SSH utilisée
La clé SSH utilisée pour se connecter aux instances EC2 n'est pas l'élément principal qui garantit l'authentification à l'hôte distant. Bien que cela offre le même niveau de sécurité que la clé dans la connexion SSH traditionnelle, dans ce flux, la clé est principalement utilisée pour assurer la compatibilité avec le client SSH. En effet, tant que le port SSH est fermé et/ou l'instance dans un réseau privé, l'élément principal qui garantit l'authentification est les identifiants AWS IAM utilisés pour ouvrir la session via AWS SSM.

Considérant cela, il est plus simple de gérer les clés privées SSH dans votre entreprise : vous pouvez créer quelques clés privées seulement (comme une pour la production, une pour d'autres environnements et une pour les services partagés/internes), les installer sur toutes les instances EC2 d'un groupe/environnement et les distribuer à tous les employés d'un type, tant que vous vous connectez à toutes vos instances via SSM. Même une fois distribuée, la connexion peut être verrouillée en modifiant le rôle AWS de chaque utilisateur ou groupe d'utilisateurs.

Une fuite de clé privée SSH n'est donc pas un incident de sécurité critique, tant que vous gardez le port SSH de l'instance EC2 fermé. En cas d'exposition de la clé, je recommande toujours de faire tourner la clé SSH, si pour une raison quelconque ou un incident, vous devez rouvrir le port 22 sur n'importe quel hôte (par exemple, un problème avec l'agent SSM qui s'exécute dans l'instance).

## Transmission des identifiants
Cette fonctionnalité permet aux utilisateurs de continuer à gérer de manière centralisée l'autorisation via AWS Identity Center ou des utilisateurs IAM, même lorsqu'un opérateur est connecté aux instances EC2. En effet, par défaut, une fois connecté à une instance EC2, les identifiants utilisés sont ceux des rôles de profil d'instance EC2. Cela peut être gênant si, par exemple, l'utilisateur doit télécharger/téléverser un fichier uniquement à partir d'un répertoire particulier qu'il possède dans S3 (ou si l'utilisation de tout autre service AWS est restreinte par utilisateur).

Si vous définissez des permissions minimales pour le rôle de profil d'instance EC2 (en gros, seulement les droits qui permettent à l'agent SSM d'interagir avec le service SSM, permettant de démarrer des sessions SSH), alors l'opérateur connecté devra utiliser ses propres identifiants (transmis par l'outil) pour effectuer des opérations supplémentaires comme accéder aux objets S3, invoquer des fonctions lambda, etc.

L'inconvénient de cette approche est que, si votre session AWS SSM a l'enregistrement activé, les identifiants utilisés peuvent apparaître dans les journaux de session dans CloudWatch, car la commande utilisée pour initier la session bash à distance exporte les identifiants obtenus localement. Cela ne devrait pas être un problème si vous limitez l'accès à ces journaux uniquement aux administrateurs, mais ces derniers pourraient effectuer des actions en tant que leurs collègues s'ils interceptent la clé dans l'heure.

Je n'utiliserais pas cette fonctionnalité lors de la connexion à des instances sensibles ou de production. En effet, cette fonctionnalité a été conçue pour les flux de travail de test et de développement où les membres de l'équipe doivent se connecter à l'instance et interagir avec les services AWS en utilisant l'AWS CLI/SDK pour mener des investigations, des expérimentations, des tests ou pour traiter/transformer des données.

## Mise en cache des identifiants
L'outil SSH-SSM proxy met en cache les identifiants obtenus localement via SSO afin d'éviter que le navigateur ne s'affiche constamment lors du montage d'un répertoire. Ces identifiants temporaires sont valides pendant 1 heure et stockés dans un fichier non crypté avec des permissions 400 dans le répertoire de l'utilisateur.

Cela ne devrait pas poser de problème si les stations de travail sont correctement sécurisées (disque dur crypté, écran verrouillé, pare-feu...). C'est de toute façon toujours beaucoup plus sûr que d'avoir des clés d'accès à long terme dans le fichier d'identification AWS standard ~/.aws/credentials.