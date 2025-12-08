# RadioManager-SaaS Frontend Dockerfile
# Multi-stage build optimisé pour Vue.js 3 + Vite 5

# Stage 1: Build de l'application
FROM node:20-alpine AS builder

# Métadonnées
LABEL maintainer="lwilly3"
LABEL description="RadioManager-SaaS Frontend - Vue.js 3 + Vite 5"
LABEL repository="https://github.com/lwilly3/radioManager-SaaS"

# Variables d'environnement de build
ARG GIT_REPO=https://github.com/lwilly3/radioManager-SaaS.git
ARG GIT_BRANCH=main
ARG NODE_ENV=production

# Définir le répertoire de travail
WORKDIR /app

# Installer Git et les outils système nécessaires
RUN apk add --no-cache git python3 make g++

# Cloner le repository
RUN git clone -b ${GIT_BRANCH} ${GIT_REPO} .

# Installer les dépendances
# Utiliser npm ci pour une installation déterministe basée sur package-lock.json
COPY package*.json ./
RUN npm ci --only=production --ignore-scripts

# Copier tout le code source
COPY . .

# Variables d'environnement pour le build Vite
# Ces variables sont embarquées dans le build final
ARG VITE_API_BASE_URL
ARG VITE_STREAM_URL
ARG VITE_APP_TITLE
ARG VITE_APP_MODE
ARG VITE_ENABLE_REGISTRATION
ARG VITE_ENABLE_SOCIAL_SHARE
ARG VITE_THEME
ARG VITE_LANGUAGE
ARG VITE_ANALYTICS_ID

# Exposer les variables pour Vite
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
ENV VITE_STREAM_URL=${VITE_STREAM_URL}
ENV VITE_APP_TITLE=${VITE_APP_TITLE:-"RadioManager"}
ENV VITE_APP_MODE=${VITE_APP_MODE:-"production"}
ENV VITE_ENABLE_REGISTRATION=${VITE_ENABLE_REGISTRATION:-"true"}
ENV VITE_ENABLE_SOCIAL_SHARE=${VITE_ENABLE_SOCIAL_SHARE:-"true"}
ENV VITE_THEME=${VITE_THEME:-"dark"}
ENV VITE_LANGUAGE=${VITE_LANGUAGE:-"fr"}

# Build de l'application Vite
# Génère les fichiers optimisés dans /app/dist
RUN npm run build

# Vérifier que le build a réussi
RUN test -d dist || { echo "Erreur: Le dossier dist n'existe pas après le build"; exit 1; }

# Stage 2: Image de production avec Nginx
FROM nginx:alpine

# Métadonnées
LABEL maintainer="lwilly3"
LABEL description="RadioManager-SaaS Production - Nginx Alpine"
LABEL version="2.0"

# Installer les outils nécessaires pour le health check
RUN apk add --no-cache curl

# Copier les fichiers buildés depuis le stage précédent
COPY --from=builder /app/dist /usr/share/nginx/html

# Copier la configuration Nginx personnalisée pour SPA
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Créer un fichier de version pour le monitoring
ARG BUILD_DATE
ARG GIT_COMMIT
RUN echo "{\"build_date\":\"${BUILD_DATE}\",\"git_commit\":\"${GIT_COMMIT}\"}" > /usr/share/nginx/html/version.json

# Permissions appropriées
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html

# Exposer le port
EXPOSE 80

# Health check avancé
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost/health || curl -f http://localhost/ || exit 1

# Commande de démarrage
CMD ["nginx", "-g", "daemon off;"]
