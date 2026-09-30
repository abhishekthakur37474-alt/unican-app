UNICAN Flutter staff app — FCM + in-app notifications.

Context:
Admin is a React/Vite dashboard (Firebase project unican-33d3b). When admin assigns a verification address to staff, TWO things happen:

1) In-app RTDB write (already exists):
   Path: staff_notifications/{staffUid}/{notifId}
   Fields:
   - id, caseId, addressId, applicantName, phone, address
   - clientName, verificationType, priority
   - timestamp (ISO), read: false
   - type: "address_assigned"
   - message: "New Verification Assigned: Case #{caseId} ({applicantName}) at {city}."

2) Device push via FCM HTTP v1 (admin already sends this):
   Title: "New Verification Assigned"
   Body: "Case #{caseId} — {applicantName} at {city}"
   Data payload (all strings):
   - type: address_assigned
   - caseId
   - addressId
   - notificationId
   - click_action: FLUTTER_NOTIFICATION_CLICK
   Android:
   - channel_id: unican_assignments
   - sound: default
   - click_action: FLUTTER_NOTIFICATION_CLICK
   - priority: HIGH
   iOS: sound default, badge 1

Admin reads the device token from staff RTDB node in this order:
staff/{uid}/fcmToken
staff/{uid}/deviceToken
staff/{uid}/pushToken
staff/{uid}/token
OR staff/{uid}/deviceId if it looks like an FCM token (contains ":" and length > 80)

Required Flutter work (do all of this):

A) Save FCM token so admin can push
- On login / auth success, get FirebaseMessaging.instance.getToken()
- Write it to Realtime Database: staff/{uid}/fcmToken = <token>
- Also listen FirebaseMessaging.instance.onTokenRefresh and update the same path
- On logout, optionally clear fcmToken (set null) so stale devices stop getting pushes
- Request notification permission (iOS + Android 13+)

B) Android notification channel (MUST match admin)
- Create channel id exactly: unican_assignments
- Name: something like "Assignments"
- Importance: high, sound enabled
- Create this channel on app start before any push arrives

C) Receive FCM
- firebase_messaging package
- Foreground: FirebaseMessaging.onMessage → show local notification (flutter_local_notifications) using channel unican_assignments, title/body from message.notification, data from message.data
- Background/terminated: FirebaseMessaging.onBackgroundMessage (top-level handler) + onMessageOpenedApp + getInitialMessage
- When user taps notification, open the assigned case using data.caseId / data.addressId / data.notificationId

D) In-app notifications (RTDB)
- Listen staff_notifications/{currentUserUid} in realtime
- Show unread badge / list
- On open, mark read: true
- This is separate from device FCM; keep both

E) google-services / Firebase
- Same Firebase project as admin: unican-33d3b
- Android: google-services.json
- iOS: GoogleService-Info.plist + APNs key in Firebase Console if iOS needed
- Do NOT put service-account JSON in Flutter. Admin already sends FCM. Flutter only receives + saves token.

Do not change admin payload contract. Token path must be staff/{uid}/fcmToken.
