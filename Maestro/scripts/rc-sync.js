// Same as scripts/qa/rc-sync.sh + wait-subscription.sh: sends the RevenueCat webhook and reads the tier back.
// RC_WEBHOOK_AUTH and USER_ID come from scripts/qa/maestro.sh. Sets output.tier.
const webhook = JSON.stringify({
    api_version: '1.0',
    event: { id: String(Date.now()), type: EVENT_TYPE, app_user_id: USER_ID, original_app_user_id: USER_ID }
})

// The backend answers 5xx on the first sync of a user without a subscription row, but stores it.
let status = 500
for (let attempt = 0; attempt < 3 && status >= 500; attempt++) {
    status = http.post(API_BASE_URL + '/webhooks/revenuecat', {
        headers: { 'Content-Type': 'application/json', Authorization: RC_WEBHOOK_AUTH },
        body: webhook
    }).status
}
if (status >= 400) {
    throw new Error('Webhook sync failed with HTTP ' + status)
}

const login = http.post(API_BASE_URL + '/auth/login', {
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ provider: 'password', email: EMAIL, password: QA_PASSWORD })
})
const token = json(login.body).access_token

for (let attempt = 0; attempt < 30 && output.tier !== 'PREMIUM'; attempt++) {
    const subscription = http.get(API_BASE_URL + '/user/subscription', {
        headers: { Authorization: 'Bearer ' + token }
    })
    output.tier = json(subscription.body).tier
}
