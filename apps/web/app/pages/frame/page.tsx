"use client";
import { InputField } from "../../common/InputField";
import { Text } from "../../common/Title";
import { GradientBox } from "../../common/GradientBox";
import Navbar from "../../components/Navbar";
import { Shield, Users, PlusCircle } from "lucide-react";
import ButtonContainer from "../../common/ButtonContainer";
export default function Frame() {
  return (
    <div>
      <Navbar />
      <div className="flex flex-col  min-h-screen bg-gray-50 m-10 p-10">
        <Text text="Text Frame" type="h1" />
        <br />
        <Text text="Create New ROSCA" type="h1" />
        <br />
        <Text
          text="Basic Information"
          type="h2"
          icon={
            <Users className="h-6 w-6 mr-2 text-primary-600 dark:text-primary-400" />
          }
        />
        <br />
        <Text text="3-of-5 Administrative Multisig" type="h3" />
        <br />
        <Text text="Rosca Name *" type="label" />
        <br />
        <Text
          text="The first 5 members you add will become the administrative council. They will require 3 out of 5 signatures to execute administrative actions (removing defaulted members, restarting ROSCA). Payouts are automatic."
          type="pxs"
        />
        <br />
        <Text
          text="Add members to your ROSCA. Wallet address is required, name is optional for easier identification."
          type="psm"
        />
        <br />
        <InputField
          label="Rosca Name"
          id="rosca-name"
          name="rosca-name"
          value=""
          placeholder="Enter Rosca Name"
          required={true}
          onChange={() => {}}
        />
        <br />
        <ButtonContainer
          icon={<Shield className="h-5 w-5 mr-2" />}
          label="Create ROSCA"
          onClick={() => {}}
          variant="primary"
        />
        <br />
        <ButtonContainer
          icon={<PlusCircle className="h-5 w-5 mr-2" />}
          label="add "
          onClick={() => {}}
          variant="dashed"
        />
        <br />
        <GradientBox>text </GradientBox>
      </div>
    </div>
  );
}
