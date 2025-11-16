import React from "react";

import type { User } from "$app/components/Admin/Users/User";
import { WithTooltip } from "$app/components/WithTooltip";
import Pill from "$app/components/Pill";

type CompliantStatusProps = {
  user: User;
};

const CompliantStatus = ({ user }: CompliantStatusProps) => (
  <div>
    <WithTooltip tip="Risk state" position="left">
      <Pill size="small" variant={user.compliant ? "success" : "warning"}>
        {user.user_risk_state}
      </Pill>
    </WithTooltip>
  </div>
);

export default CompliantStatus;
