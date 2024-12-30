import auth0 from 'auth0-js'

const webAuth = new auth0.WebAuth({
    domain: import.meta.env.VITE_OAUTH_DOMAIN, // e.g., you.auth0.com
    clientID: import.meta.env.VITE_OAUTH_CLIENT_ID,
    redirectUri: import.meta.env.VITE_OAUTH_REDIRECT_URI,
    scope: 'openid profile email',
    responseType: 'token id_token',
    // connection: 'google-oauth2',
    audience: import.meta.env.VITE_OAUTH_AUDIENCE
});

async function getAuthToken () {

}

export function initializeOauthPorts(app) {
    app.ports.loginRedirect.subscribe(() => {
        webAuth.authorize()
    });
    app.ports.logoutRedirect.subscribe(() => {
        webAuth.logout({
            clientID: import.meta.env.VITE_OAUTH_CLIENT_ID,
            returnTo: import.meta.env.VITE_OUATH_LOGOUT_URI
        })
    })
    
}