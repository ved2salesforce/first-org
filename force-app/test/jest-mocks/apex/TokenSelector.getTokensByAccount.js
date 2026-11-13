import { createApexTestWireAdapter } from "@salesforce/wire-service-jest-util";

const getTokensByAccount = createApexTestWireAdapter(jest.fn());
export default getTokensByAccount;
