/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
*/
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.disableUser = functions.firestore
    .document('users/{userId}')
    .onUpdate((change, context) => {
        const userData = change.after.data();
        const userId = context.params.userId;

        if (userData.isDisabled) {
            return admin.auth().revokeRefreshTokens(userId)
                .then(() => {
                    console.log(`Revoked tokens for user: ${userId}`);
                })
                .catch((error) => {
                    console.error("Error revoking tokens:", error);
                });
        } else {
            return null;
        }
    });
