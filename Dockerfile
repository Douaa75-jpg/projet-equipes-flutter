# Étape 1 : Utiliser l’image officielle Flutter
FROM ghcr.io/cirruslabs/flutter:latest AS build

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers du projet
COPY . .

# Activer Flutter Web et effectuer un build
RUN flutter config --enable-web \
    && flutter pub get \
    && flutter build web

# Étape 2 : Utiliser un serveur Nginx pour servir l’application
FROM nginx:alpine

# Copier les fichiers de build Flutter Web vers Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Exposer le port 80
EXPOSE 80

# Lancer Nginx
CMD ["nginx", "-g", "daemon off;"]
