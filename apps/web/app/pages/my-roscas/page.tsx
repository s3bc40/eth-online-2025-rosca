import { Text } from "../../common/Title";
import Navbar from "../../components/Navbar";

export default function RoscaList() {
  return (
    <div>
      <Navbar />
      <div className="flex flex-col items-center justify-center min-h-screen bg-gray-50">
        <h1 className="text-3xl font-bold text-gray-800">Rosca List</h1>
        <p className="mt-4 text-gray-600">Here are your Rosca groups.</p>
        <Text text="Rosca List" type="h1" />
        <Text text="Rosca List" type="h2" />
        <Text text="Rosca List" type="h3" />
        <Text text="Rosca List" type="label" />
        <Text text="Rosca List" type="pxs" />
        <Text text="Rosca List" type="psm" />
      </div>
    </div>
  );
}
