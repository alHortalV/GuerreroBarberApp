/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {Request, Response} from "express"; // Importa los tipos de Express


// Importa el archivo de credenciales del servicio Firebase
import * as serviceAccount from "./guerrerobarberapp-firebase-adminsdk.json";

// Inicializa el Admin SDK usando las credenciales de tu archivo JSON.
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
});

// Función HTTPS para asignar el custom claim "admin" a un usuario
export const setAdminClaim = functions.https.onRequest(
  async (req: Request, res: Response) => {
    const uidParam = req.query.uid;
    // Verifica que uidParam exista y sea un string
    if (!uidParam || typeof uidParam !== "string") {
      res
        .status(400)
        .send("UID is required as a query parameter and must be a string.");
      return;
    }
    const uid: string = uidParam;
    try {
      await admin.auth().setCustomUserClaims(uid, {admin: true});
      res.send(`Custom claim "admin" was set for user ${uid}`);
    } catch (error) {
      res.status(500).send(`Error setting custom claim: ${error}`);
    }
  }
);
