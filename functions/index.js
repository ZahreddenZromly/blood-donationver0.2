const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Function to send notification when a donation request is canceled
exports.sendCancelRequestNotification = functions.firestore
    .document('donation_requests/{requestId}')
    .onUpdate((change, context) => {
        // Check if the request status is 'Canceled'
        const beforeStatus = change.before.data().requestStatus;
        const afterStatus = change.after.data().requestStatus;

        if (beforeStatus === 'Pending' && afterStatus === 'Canceled') {
            const requestData = change.after.data();
            const userId = requestData.userId; // The user ID of the person who made the request
            const explanation = requestData.explanation || "No explanation provided.";

            // Get the FCM token of the user
            return admin.firestore().collection('users').doc(userId).get()
                .then(userDoc => {
                    const fcmToken = userDoc.data()?.fcmToken;
                    if (fcmToken) {
                        // Prepare the notification payload
                        const message = {
                            notification: {
                                title: 'Your Donation Request Canceled',
                                body: 'Your request has been canceled. Reason: ' + explanation,
                            },
                            token: fcmToken,
                        };

                        // Send the notification
                        return admin.messaging().send(message);
                    }
                    return null;
                })
                .then(response => {
                    console.log("Successfully sent message:", response);
                })
                .catch(error => {
                    console.log("Error sending message:", error);
                });
        }
        return null;
    });
