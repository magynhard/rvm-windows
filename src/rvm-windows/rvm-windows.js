//<!-- MODULE -->//
if (typeof require === 'function' && typeof module !== 'undefined' && module.exports) {
    var LuckyCase = require('lucky-case');
}
//<!-- /MODULE -->//

/**
 * Typifier
 *
 * The javascript library to get or check the type of a given variable.
 *
 */
class RvmWindows {
    /**
     * Get the version of the used library
     * @returns {string}
     */
    static getVersion() {
        const self = RvmWindows;
        return self._version;
    }
}

/**
 * @type {string}
 * @private
 */
RvmWindows._version = "0.0.21";

//<!-- MODULE -->//
if (typeof module !== 'undefined' && module.exports) {
    module.exports = RvmWindows;
}
//<!-- /MODULE -->//