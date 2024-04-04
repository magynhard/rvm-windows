
const RvmCliInit = require("./../cli/tasks/_init");

console.log("Adding RVM wrappers to PATH environment variable ...");
RvmCliInit.ensureWrapperPathEnvIsSet(true);
console.log("Successfully added!");