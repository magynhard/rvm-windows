<a name="RvmWindows"></a>

## RvmWindows
RvmWindows

The javascript library to get or check the type of a given variable.

* [RvmWindows](#Typifier)
    * [.getVersion()](#Typifier.getVersion) &rarr; <code>string</code>
    * [.isArray(value)](#Typifier.isArray) &rarr; <code>boolean</code>
    * [.isObject(value)](#Typifier.isObject) &rarr; <code>boolean</code>
    * [.isString(value)](#Typifier.isString) &rarr; <code>boolean</code>
    * [.isStringClass(value)](#Typifier.isStringClass) &rarr; <code>boolean</code>
    * [.isNumber(value)](#Typifier.isNumber) &rarr; <code>boolean</code>
    * [.isNumberClass(value)](#Typifier.isNumberClass) &rarr; <code>boolean</code>
    * [.isNumberString(value)](#Typifier.isNumberString) &rarr; <code>boolean</code>
    * [.isDate(value)](#Typifier.isDate) &rarr; <code>boolean</code>
    * [.isRegExp(value)](#Typifier.isRegExp) &rarr; <code>boolean</code>
    * [.isNaN(value)](#Typifier.isNaN) &rarr; <code>boolean</code>
    * [.isInfinity(value)](#Typifier.isInfinity) &rarr; <code>boolean</code>
    * [.isUndefined(value)](#Typifier.isUndefined) &rarr; <code>boolean</code>
    * [.isNull(value)](#Typifier.isNull) &rarr; <code>boolean</code>
    * [.isBoolean(value)](#Typifier.isBoolean) &rarr; <code>boolean</code>
    * [.isBooleanClass(value)](#Typifier.isBooleanClass) &rarr; <code>boolean</code>
    * [.isFunction(value)](#Typifier.isFunction) &rarr; <code>boolean</code>
    * [.isClass(value)](#Typifier.isClass) &rarr; <code>boolean</code>
    * [.is(type, value)](#Typifier.is) &rarr; <code>boolean</code>
    * [.isSet(variable)](#Typifier.isSet) &rarr; <code>boolean</code>
    * [.getType(value)](#Typifier.getType) &rarr; <code>string</code>

<a name="RvmWindows.getVersion"></a>

### RvmWindows.getVersion() &rarr; <code>string</code>
Get the version of the used library
<a name="RvmWindows.isArray"></a>

### RvmWindows.isArray(value) &rarr; <code>boolean</code>
Check if given variable is of type Array

**Returns**: <code>boolean</code> - true if Array, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isObject"></a>

### RvmWindows.isObject(value) &rarr; <code>boolean</code>
Check if given variable is of type Object

**Returns**: <code>boolean</code> - true if Object, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isString"></a>

### RvmWindows.isString(value) &rarr; <code>boolean</code>
Check if given variable is of type string (primitive)

**Returns**: <code>boolean</code> - true if 'string', otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isStringClass"></a>

### RvmWindows.isStringClass(value) &rarr; <code>boolean</code>
Check if given variable is of type String (class instance)

**Returns**: <code>boolean</code> - true if instance of class 'String', otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isNumber"></a>

### RvmWindows.isNumber(value) &rarr; <code>boolean</code>
Check if given variable is of type number (primitive)

**Returns**: <code>boolean</code> - true if 'number', otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isNumberClass"></a>

### RvmWindows.isNumberClass(value) &rarr; <code>boolean</code>
Check if given variable is of type Number (class instance)

**Returns**: <code>boolean</code> - true if instance of class 'Number', otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isNumberString"></a>

### RvmWindows.isNumberString(value) &rarr; <code>boolean</code>
Check if given variable is a valid number inside a string that evaluates to a number in Javascript.

**Returns**: <code>boolean</code> - true if valid JavaScript number inside string  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 


**Example**
```js
// valid number strings
     '200'
     '25.75'
     '10.'
     '.5'
     '500_000'
     '0x12F'
```
<a name="RvmWindows.isDate"></a>

### RvmWindows.isDate(value) &rarr; <code>boolean</code>
Check if given variable is of type Date

**Returns**: <code>boolean</code> - true if Date, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isRegExp"></a>

### RvmWindows.isRegExp(value) &rarr; <code>boolean</code>
Check if given variable is of type RegExp

**Returns**: <code>boolean</code> - true if RegExp, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isNaN"></a>

### RvmWindows.isNaN(value) &rarr; <code>boolean</code>
Check if given variable is of type NaN

**Returns**: <code>boolean</code> - true if NaN, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isInfinity"></a>

### RvmWindows.isInfinity(value) &rarr; <code>boolean</code>
Check if given variable is of type Infinity

**Returns**: <code>boolean</code> - true if Infinity, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isUndefined"></a>

### RvmWindows.isUndefined(value) &rarr; <code>boolean</code>
Check if given variable is of type undefined

**Returns**: <code>boolean</code> - true if undefined, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isNull"></a>

### RvmWindows.isNull(value) &rarr; <code>boolean</code>
Check if given variable is of type null

**Returns**: <code>boolean</code> - true if null, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isBoolean"></a>

### RvmWindows.isBoolean(value) &rarr; <code>boolean</code>
Check if given variable is of type boolean (primitive)

**Returns**: <code>boolean</code> - true if 'boolean' or instance of class 'Boolean', otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isBooleanClass"></a>

### RvmWindows.isBooleanClass(value) &rarr; <code>boolean</code>
Check if given variable is of type Boolean (class instance)

**Returns**: <code>boolean</code> - true if instance of class 'Boolean', otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isFunction"></a>

### RvmWindows.isFunction(value) &rarr; <code>boolean</code>
Check if given variable is of type function

**Returns**: <code>boolean</code> - true if function, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.isClass"></a>

### RvmWindows.isClass(value) &rarr; <code>boolean</code>
Check if given variable is of type class

**Returns**: <code>boolean</code> - true if class, otherwise false  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 

<a name="RvmWindows.is"></a>

### RvmWindows.is(type, value) &rarr; <code>boolean</code>
Check if the given value is of the given type.

**Returns**: <code>boolean</code> - true if the value is of the given type  

| Param | Type |
| --- | --- |
| type | <code>string</code> | 
| value | <code>any</code> | 


**Example**

```js
RvmWindows.is('Array', [1, 2, 3]) // => true
```
<a name="RvmWindows.isSet"></a>

### RvmWindows.isSet(variable) &rarr; <code>boolean</code>
Check if the given variable is set (is not undefined, null or NaN).
Valid values like 'false', a empty string or '0' return true.

**Returns**: <code>boolean</code> - true if the value is set  

| Param | Type |
| --- | --- |
| variable | <code>any</code> | 


**Example**

```js
let a;
let b = 0;
RvmWindows.isSet(a) // => false
RvmWindows.isSet(b) // => true
```
<a name="RvmWindows.getType"></a>

### RvmWindows.getType(value) &rarr; <code>string</code>
Get the type of the given value.
Primitive types are lower case.

**Returns**: <code>string</code> - type in pascal case format  

| Param | Type |
| --- | --- |
| value | <code>any</code> | 


**Example**
```js
'Object'
```

**Example**
```js
'string'
```
