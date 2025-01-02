import auth0 from 'auth0-js'
import ms from 'ms'
import {SignJWT} from 'jose'

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
    const onProduction = import.meta.env.PROD
    if (onProduction) {
        return () => {
            localStorage.removeItem(ACCESS_TOKEN_KEY)
            localStorage.removeItem(USER_PROFILE)
            webAuth.authorize()
        }
    }
    return () => {
        localStorage.removeItem(ACCESS_TOKEN_KEY)
        localStorage.removeItem(USER_PROFILE)
        window.location.href = "http://localhost:3001/JUWURA/callback"
    }
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
    const onProduction = import.meta.env.PROD
    if (onProduction) {
        return () => {
            webAuth.parseHash({}, (err, authResult) => {
                if (err) {
                    console.error(err)
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

    return async () => {
        const secretKey = import.meta.env.VITE_OAUTH_TEST_SECRET_KEY
        const expirationTime = import.meta.env.VITE_OAUTH_TEST_EXPIRATION_TIME

        const testAccessToken = await generateTestToken(secretKey, expirationTime)
        const testProfile = import.meta.env.VITE_OAUTH_TEST_PROFILE
        localStorage.setItem(ACCESS_TOKEN_KEY, testAccessToken)
        localStorage.setItem(USER_PROFILE, testProfile)
        app.ports.onOauthResult.send(true)
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
            if (isAccessTokenExpired(accessToken)) {
                throw Error("Token expired")
            }
            app.ports.onCheckedUserSession.send({accessToken, profile})
        } catch (err){
            console.error(`Error retreiving token: ${err}`)
            app.ports.onCheckedUserSession.send(null)
        }
    }
}

function isAccessTokenExpired(token) {
    try {
        // Split the JWT into its three parts (header, payload, signature)
        const parts = token.split(".");
        if (parts.length !== 3) {
            throw new Error("Invalid token format");
        }

        // Decode the payload (it's Base64URL encoded)
        const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
        console.log(payload)

        const exp = payload.exp;
        if (!exp) {
            throw new Error("Token does not contain 'exp' claim");
        }

        const currentTime = Math.floor(Date.now() / 1000);

        return currentTime >= exp;
    } catch (error) {
        console.error("Failed to decode token or check expiration:", error);
        return true;
    }
}

async function generateTestToken(secretKey, expirationTime) {
    // Generate expiration time
    const durationMs = ms(expirationTime)
    if (!durationMs) {
        throw new Error("Invalid expiration time format");
    }
    const expirationDate = Math.floor((Date.now() + durationMs) / 1000); 

       const payload = {
        iss: "https://dev-icycqcxl2ssnfnq8.us.auth0.com/",
        sub: "google-oauth2|106745117575550349372",
        aud: ["https://api-juwura"],
        iat: Math.floor(Date.now() / 1000),
        exp: expirationDate,
        scope: "openid profile email",
        azp: "ytw7eULrMpohTMO2HfGHjaR8VefgVIun",
    };

    const secret = new TextEncoder().encode(secretKey); 
    const token = await new SignJWT(payload)
        .setProtectedHeader({ alg: "HS256" , typ: "JWT"}) 
        .sign(secret);

    return token;
}

export function initializeOauthPorts(app) {
    app.ports.loginRedirect.subscribe(loginRedirect());
    app.ports.logoutRedirect.subscribe(logoutRedirect)
    app.ports.parseCallback.subscribe(parseCallbackConstructor(app))
    app.ports.checkUserSession.subscribe(checkUserSessionConstructor(app))
}