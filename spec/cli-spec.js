const Typifier = require('../src/rvm-windows/rvm-windows.js');
require('ruby-nice/object');

//----------------------------------------------------------------------------------------------------

describe('Typifier', function () {
    beforeEach(function () {
    });
    it('can return a version', function () {
        expect(RvmWindows.getVersion()).toContain('.');
    });
});

//----------------------------------------------------------------------------------------------------

describe('Typifier', function () {
    beforeEach(function () {
    });
    describe('.isNumber()', function () {
        it('can recognize valid numbers', function () {
            [1, 1.1, 1., .1, 500_000, 500.0_1, 1_5., 0x111, 0xA0F, 0x0].eachWithIndex((val, i) => {
                expect(RvmWindows.isNumber(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid number (string)', function () {
            expect(RvmWindows.isNumber('1')).toEqual(false);
        });
        it('can recognize invalid number (null)', function () {
            expect(RvmWindows.isNumber(null)).toEqual(false);
        });
        it('can recognize invalid number (undefined)', function () {
            expect(RvmWindows.isNumber(undefined)).toEqual(false);
        });
        it('can recognize invalid number (object)', function () {
            expect(RvmWindows.isNumber({})).toEqual(false);
        });
        it('can recognize invalid number (NaN)', function () {
            expect(RvmWindows.isNumber(NaN)).toEqual(false);
        });
        it('can recognize invalid number (Infinity)', function () {
            expect(RvmWindows.isNumber(Infinity)).toEqual(false);
        });
    });
    describe('.isNumberClass()', function () {
        it('can recognize valid numbers classes', function () {
            [new Number(1), new Number(1.1), new Number(1.), new Number(.1), new Number(500_000), new Number(500.0_1), new Number(1_5.), new Number(0x111), new Number(0xA0F), new Number(0x0)].eachWithIndex((val, i) => {
                expect(RvmWindows.isNumberClass(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid number class (string)', function () {
            expect(RvmWindows.isNumberClass('1')).toEqual(false);
        });
        it('can recognize invalid number class (null)', function () {
            expect(RvmWindows.isNumberClass(null)).toEqual(false);
        });
        it('can recognize invalid number class (undefined)', function () {
            expect(RvmWindows.isNumberClass(undefined)).toEqual(false);
        });
        it('can recognize invalid number class (object)', function () {
            expect(RvmWindows.isNumberClass({})).toEqual(false);
        });
        it('can recognize invalid number class (NaN)', function () {
            expect(RvmWindows.isNumberClass(NaN)).toEqual(false);
        });
        it('can recognize invalid number class (Infinity)', function () {
            expect(RvmWindows.isNumberClass(Infinity)).toEqual(false);
        });
    });
    describe('.isNumberString()', function () {
        it('can recognize valid number strings', function () {
            ['1', '1.1', '1.', '.1', '500_000', '500.0_1', '1_5.', '0x111', '0xA0F', '0x0'].eachWithIndex((val, i) => {
                expect(RvmWindows.isNumberString(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid number strings', function () {
            ['.', '_1.1', '1._', 'number', 'null', '2,5', '0xA0G'].eachWithIndex((val, i) => {
                expect(RvmWindows.isNumberString(val)).toEqual(false, val);
            });
        });
        it('can recognize invalid number string (number)', function () {
            expect(RvmWindows.isNumberString(1)).toEqual(false);
        });
        it('can recognize invalid number string (null)', function () {
            expect(RvmWindows.isNumberString(null)).toEqual(false);
        });
        it('can recognize invalid number string (undefined)', function () {
            expect(RvmWindows.isNumberString(undefined)).toEqual(false);
        });
        it('can recognize invalid number string (object)', function () {
            expect(RvmWindows.isNumberString({})).toEqual(false);
        });
        it('can recognize invalid number string (NaN)', function () {
            expect(RvmWindows.isNumberString(NaN)).toEqual(false);
        });
        it('can recognize invalid number string (Infinity)', function () {
            expect(RvmWindows.isNumberString(Infinity)).toEqual(false);
        });
    });
    describe('.isNull()', function () {
        it('can recognize null value', function () {
            [null].eachWithIndex((val, i) => {
                expect(RvmWindows.isNull(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid number string (number)', function () {
            expect(RvmWindows.isNull(1)).toEqual(false);
        });
        it('can recognize invalid number string (string)', function () {
            expect(RvmWindows.isNull('null')).toEqual(false);
        });
        it('can recognize invalid number string (undefined)', function () {
            expect(RvmWindows.isNull(undefined)).toEqual(false);
        });
        it('can recognize invalid number string (object)', function () {
            expect(RvmWindows.isNull({})).toEqual(false);
        });
        it('can recognize invalid number string (NaN)', function () {
            expect(RvmWindows.isNull(NaN)).toEqual(false);
        });
        it('can recognize invalid number string (Infinity)', function () {
            expect(RvmWindows.isNull(Infinity)).toEqual(false);
        });
    });
    describe('.isNaN()', function () {
        it('can recognize NaN value', function () {
            [NaN].eachWithIndex((val, i) => {
                expect(RvmWindows.isNaN(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid NaN (number)', function () {
            expect(RvmWindows.isNaN(1)).toEqual(false);
        });
        it('can recognize invalid NaN (string)', function () {
            expect(RvmWindows.isNaN('null')).toEqual(false);
        });
        it('can recognize invalid NaN (undefined)', function () {
            expect(RvmWindows.isNaN(undefined)).toEqual(false);
        });
        it('can recognize invalid NaN (object)', function () {
            expect(RvmWindows.isNaN({})).toEqual(false);
        });
        it('can recognize invalid NaN (null)', function () {
            expect(RvmWindows.isNaN(null)).toEqual(false);
        });
        it('can recognize invalid NaN (Infinity)', function () {
            expect(RvmWindows.isNaN(Infinity)).toEqual(false);
        });
    });
    describe('.isInfinity()', function () {
        it('can recognize Infinity value', function () {
            [Infinity].eachWithIndex((val, i) => {
                expect(RvmWindows.isInfinity(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid Infinity (number)', function () {
            expect(RvmWindows.isInfinity(1)).toEqual(false);
        });
        it('can recognize invalid Infinity (string)', function () {
            expect(RvmWindows.isInfinity('null')).toEqual(false);
        });
        it('can recognize invalid Infinity (undefined)', function () {
            expect(RvmWindows.isInfinity(undefined)).toEqual(false);
        });
        it('can recognize invalid Infinity (object)', function () {
            expect(RvmWindows.isInfinity({})).toEqual(false);
        });
        it('can recognize invalid Infinity (null)', function () {
            expect(RvmWindows.isInfinity(null)).toEqual(false);
        });
        it('can recognize invalid Infinity (NaN)', function () {
            expect(RvmWindows.isInfinity(NaN)).toEqual(false);
        });
    });
    describe('.isObject()', function () {
        it('can recognize object value', function () {
            [{}].eachWithIndex((val, i) => {
                expect(RvmWindows.isObject(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid object (number)', function () {
            expect(RvmWindows.isObject(1)).toEqual(false);
        });
        it('can recognize invalid object (string)', function () {
            expect(RvmWindows.isObject('null')).toEqual(false);
        });
        it('can recognize invalid object (undefined)', function () {
            expect(RvmWindows.isObject(undefined)).toEqual(false);
        });
        it('can recognize invalid object (Infinity)', function () {
            expect(RvmWindows.isObject(Infinity)).toEqual(false);
        });
        it('can recognize invalid object (null)', function () {
            expect(RvmWindows.isObject(null)).toEqual(false);
        });
        it('can recognize invalid object (NaN)', function () {
            expect(RvmWindows.isObject(NaN)).toEqual(false);
        });
    });
    describe('.isUndefined()', function () {
        it('can recognize undefined value', function () {
            [undefined].eachWithIndex((val, i) => {
                expect(RvmWindows.isUndefined(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid undefined (number)', function () {
            expect(RvmWindows.isUndefined(1)).toEqual(false);
        });
        it('can recognize invalid undefined (string)', function () {
            expect(RvmWindows.isUndefined('null')).toEqual(false);
        });
        it('can recognize invalid undefined (object)', function () {
            expect(RvmWindows.isUndefined({})).toEqual(false);
        });
        it('can recognize invalid undefined (Infinity)', function () {
            expect(RvmWindows.isUndefined(Infinity)).toEqual(false);
        });
        it('can recognize invalid undefined (null)', function () {
            expect(RvmWindows.isUndefined(null)).toEqual(false);
        });
        it('can recognize invalid undefined (NaN)', function () {
            expect(RvmWindows.isUndefined(NaN)).toEqual(false);
        });
    });
    describe('.isString()', function () {
        it('can recognize string value', function () {
            ['string'].eachWithIndex((val, i) => {
                expect(RvmWindows.isString(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid string (number)', function () {
            expect(RvmWindows.isString(1)).toEqual(false);
        });
        it('can recognize invalid string (undefined)', function () {
            expect(RvmWindows.isString(undefined)).toEqual(false);
        });
        it('can recognize invalid string (object)', function () {
            expect(RvmWindows.isString({})).toEqual(false);
        });
        it('can recognize invalid string (Infinity)', function () {
            expect(RvmWindows.isString(Infinity)).toEqual(false);
        });
        it('can recognize invalid string (null)', function () {
            expect(RvmWindows.isString(null)).toEqual(false);
        });
        it('can recognize invalid string (NaN)', function () {
            expect(RvmWindows.isString(NaN)).toEqual(false);
        });
    });
    describe('.isFunction()', function () {
        it('can recognize anonymous arrow function value', function () {
            [() => {
            }].eachWithIndex((val, i) => {
                expect(RvmWindows.isFunction(val)).toEqual(true, val);
            });
        });
        it('can recognize anonymous function value', function () {
            [function () {
            }].eachWithIndex((val, i) => {
                expect(RvmWindows.isFunction(val)).toEqual(true, val);
            });
        });
        it('can recognize invalid function (number)', function () {
            expect(RvmWindows.isFunction(1)).toEqual(false);
        });
        it('can recognize invalid function (undefined)', function () {
            expect(RvmWindows.isFunction(undefined)).toEqual(false);
        });
        it('can recognize invalid function (object)', function () {
            expect(RvmWindows.isFunction({})).toEqual(false);
        });
        it('can recognize invalid function (Infinity)', function () {
            expect(RvmWindows.isFunction(Infinity)).toEqual(false);
        });
        it('can recognize invalid function (null)', function () {
            expect(RvmWindows.isFunction(null)).toEqual(false);
        });
        it('can recognize invalid function (NaN)', function () {
            expect(RvmWindows.isFunction(NaN)).toEqual(false);
        });
        it('can recognize invalid function (class)', function () {
            class TestClass {
            }

            expect(RvmWindows.isFunction(TestClass)).toEqual(false);
        });
    });
});
//----------------------------------------------------------------------------------------------------

describe('Typifier.getType', function () {
    beforeEach(function () {
    });
    it('can recognize a string value', function () {
        ['1', '1.1', '1.', '.1', '500_000', '500.0_1', '1_5.', '0x111', '0xA0F', '0x0'].eachWithIndex((val, i) => {
            expect(RvmWindows.getType(val)).toEqual('string');
        });
    });
    it('can recognize a null value', function () {
        expect(RvmWindows.getType(null)).toEqual('null');
    });
    it('can recognize a number value', function () {
        [1, 1.1, 1., .1, 500_000, 500.0_1, 1_5., 0x111, 0xA0F, 0x0].eachWithIndex((val, i) => {
            expect(RvmWindows.getType(val)).toEqual('number');
        });
    });
    it('can recognize a number class value', function () {
        [new Number(1), new Number(1.1), new Number(1.), new Number(.1), new Number(500_000), new Number(500.0_1), new Number(1_5.), new Number(0x111), new Number(0xA0F), new Number(0x0)].eachWithIndex((val, i) => {
            expect(RvmWindows.getType(val)).toEqual('Number');
        });
    });
});

//----------------------------------------------------------------------------------------------------

describe('Typifier.isSet', function () {
    beforeEach(function () {
    });
    // falsy
    it('recognizes a undefined variable', function () {
        let a;
        expect(RvmWindows.isSet(a)).toEqual(false);
    });
    it('recognizes a variable of null value', function () {
        let a = null;
        expect(RvmWindows.isSet(a)).toEqual(false);
    });
    it('recognizes a NaN variable', function () {
        let a = NaN;
        expect(RvmWindows.isSet(a)).toEqual(true);
    });
    // truthy
    it('recognizes a variable of value 0', function () {
        let a = 0;
        expect(RvmWindows.isSet(a)).toEqual(true);
    });
    it('recognizes a variable of value false', function () {
        let a = false;
        expect(RvmWindows.isSet(a)).toEqual(true);
    });
    it('recognizes a variable with empty string', function () {
        let a = '';
        expect(RvmWindows.isSet(a)).toEqual(true);
    });
});

//----------------------------------------------------------------------------------------------------