import auth0 from 'auth0-js'

const webAuth = new auth0.WebAuth({
    domain: import.meta.env.VITE_OAUTH_DOMAIN, // e.g., you.auth0.com
    clientID: import.meta.env.VITE_OAUTH_CLIENT_ID,
    redirectUri: import.meta.env.VITE_OAUTH_REDIRECT_URI,
    scope: 'openid profile email',
    responseType: 'code',
    connection: 'google'
    // audience: import.meta.env.VITE_OAUTH_AUDIENCE
});

async function getAuthToken () {

}

export function initializeOauthPorts(app) {
    app.ports.loginRedirect.subscribe(() => {
        webAuth.authorize()
    });
}