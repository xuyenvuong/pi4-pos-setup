FROM node:12-alpine
WORKDIR /pos-setup
COPY package.json yarn.lock ./
RUN yarn install --production
COPY . .
CMD ["node", "src/index.js"]