import * as React from "react";
import { Alert } from "$app/components/Alert";

export const InvalidNameForEmailDeliveryWarning: React.FC = () => (
  <Alert variant="warning">
    <div>
      Your name contains a colon (:) which causes email delivery problems and will be removed from the sender name when
      emails are sent. <a href={Routes.settings_profile_path()}>Update your name</a> to fix this.
    </div>
  </Alert>
);
