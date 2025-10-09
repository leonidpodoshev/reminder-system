# Reminder System Frontend

React-based frontend for the Reminder System.

## Setup

```bash
# Install dependencies
npm install

# Start development server
npm start

# Build for production
npm run build

# Run tests
npm test
```

## Environment Variables

Create a `.env` file:

```
REACT_APP_API_URL=http://localhost:8080
```

## Development

The app will run on http://localhost:3000 and proxy API requests to the backend.

## Docker

```bash
# Build
docker build -t reminder-frontend .

# Run
docker run -p 3000:80 reminder-frontend
```

## Features

- Create/Edit/Delete reminders
- Filter by notification type (Email/SMS)
- Responsive design
- Modern UI with Tailwind CSS
- Real-time updates

