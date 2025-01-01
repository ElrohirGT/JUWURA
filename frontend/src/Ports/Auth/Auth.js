import auth0 from 'auth0-js'

const ACCESS_TOKEN_KEY = "access_token"
const USER_PROFILE = "user_profile"
const webAuth = new auth0.WebAuth({
    domain: import.meta.env.VITE_OAUTH_DOMAIN, // e.g., you.auth0.com
    clientID: import.meta.env.VITE_OAUTH_CLIENT_ID,
    redirectUri: import.meta.env.VITE_OAUTH_REDIRECT_URI,
    scope: 'openid profile email',
    responseType: 'token id_token',
    // connection: 'google-oauth2',
    audience: import.meta.env.VITE_OAUTH_AUDIENCE
});

function loginRedirect() {
    localStorage.removeItem(ACCESS_TOKEN_KEY)
    localStorage.removeItem(USER_PROFILE)
    webAuth.authorize()
}

function logoutRedirect() {
    webAuth.logout({
        clientID: import.meta.env.VITE_OAUTH_CLIENT_ID,
        returnTo: import.meta.env.VITE_OUATH_LOGOUT_URI
    })
    localStorage.removeItem(ACCESS_TOKEN_KEY)
    localStorage.removeItem(USER_PROFILE)
}

function parseCallbackConstructor (app) {
    return () => {
        webAuth.parseHash({}, (err, authResult) => {
            if (err) {
                app.ports.onOauthResult.send(false)
            } else {
                console.log(authResult)
                const profile = {
                    username: authResult.idTokenPayload.name,
                    email: authResult.idTokenPayload.email,
                    photo: authResult.idTokenPayload.picture
                }
                localStorage.setItem(ACCESS_TOKEN_KEY, authResult.accessToken)
                localStorage.setItem(USER_PROFILE, JSON.stringify(profile))
                app.ports.onOauthResult.send(true)
            }
        })
    }
}

function checkUserSessionConstructor(app) {
    return () => {
        try {
            const accessToken = localStorage.getItem(ACCESS_TOKEN_KEY)
            const profile = JSON.parse(localStorage.getItem(USER_PROFILE))
            if (!profile || !accessToken) {
                throw Error("Access token or user_profile are empty")
            }
            app.ports.onCheckedUserSession.send({accessToken, profile})
        } catch (err){
            console.error(`Error retreiving token: ${err}`)
            app.ports.onCheckedUserSession.send(null)
        }
    }
}

export function initializeOauthPorts(app) {
    app.ports.loginRedirect.subscribe(loginRedirect);
    app.ports.logoutRedirect.subscribe(logoutRedirect)
    app.ports.parseCallback.subscribe(parseCallbackConstructor(app))
    app.ports.checkUserSession.subscribe(checkUserSessionConstructor(app))
}