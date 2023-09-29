# Selecciona la imagen base
FROM node:18

# Directorio de trabajo dentro del contenedor
WORKDIR /usr/src/app

# Copia el archivo package.json (y package-lock.json si existe) al directorio de trabajo
COPY package*.json ./

# Instala las dependencias del proyecto
RUN npm install

# Copia el resto del código de la aplicación al directorio de trabajo
COPY . .

# Expone el puerto en el que se ejecutará la aplicación (p.ej. 3000 para una app Express por defecto)
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["npm", "run", "start"]
