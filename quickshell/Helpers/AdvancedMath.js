// Helper function to convert degrees to radians
function toRadians(degrees) {
	return degrees * (Math.PI / 180);
}

// Helper function to convert radians to degrees
function toDegrees(radians) {
	return radians * (180 / Math.PI);
}

// Constants
var constants = {
	PI: Math.PI,
	E: Math.E,
	LN2: Math.LN2,
	LN10: Math.LN10,
	LOG2E: Math.LOG2E,
	LOG10E: Math.LOG10E,
	SQRT1_2: Math.SQRT1_2,
	SQRT2: Math.SQRT2
};

// Safe evaluation function that handles advanced math using recursive descent parser
// This avoids the security risk of using eval()
function evaluate(expression) {
	try {
		// Tokenize and validate first
		var tokens = tokenize(expression);
		if (tokens.length === 0) {
			throw new Error("Empty expression");
		}

		// Parse and evaluate using recursive descent
		var parser = new ExpressionParser(tokens);
		var result = parser.parse();

		if (!isFinite(result) || isNaN(result)) {
			throw new Error("Invalid result");
		}

		return result;
	} catch (error) {
		throw new Error("Evaluation failed: " + error.message);
	}
}

// Tokenizer - converts input string to safe tokens
function tokenize(expression) {
	var tokens = [];
	var i = 0;
	
	while (i < expression.length) {
		var char = expression[i];
		
		// Skip whitespace
		if (/\s/.test(char)) {
			i++;
			continue;
		}
		
		// Numbers (including decimals)
		if (/[0-9.]/.test(char)) {
			var num = '';
			while (i < expression.length && /[0-9.]/.test(expression[i])) {
				num += expression[i];
				i++;
			}
			if (isNaN(parseFloat(num))) {
				throw new Error("Invalid number: " + num);
			}
			tokens.push({ type: 'NUMBER', value: parseFloat(num) });
			continue;
		}
		
		// Identifiers (function names and constants)
		if (/[a-zA-Z_]/.test(char)) {
			var ident = '';
			while (i < expression.length && /[a-zA-Z0-9_]/.test(expression[i])) {
				ident += expression[i];
				i++;
			}
			
			// Map identifiers to constants or function names
			var lower = ident.toLowerCase();
			if (lower === 'pi') {
				tokens.push({ type: 'NUMBER', value: Math.PI });
			} else if (lower === 'e') {
				tokens.push({ type: 'NUMBER', value: Math.E });
			} else if (lower === 'ln2') {
				tokens.push({ type: 'NUMBER', value: Math.LN2 });
			} else if (lower === 'ln10') {
				tokens.push({ type: 'NUMBER', value: Math.LN10 });
			} else if (isValidFunction(lower)) {
				tokens.push({ type: 'FUNCTION', value: lower });
			} else {
				throw new Error("Unknown identifier: " + ident);
			}
			continue;
		}
		
		// Operators and punctuation
		if (/[+\-*/(),%^]/.test(char)) {
			tokens.push({ type: 'OPERATOR', value: char });
			i++;
			continue;
		}
		
		// Invalid character
		throw new Error("Invalid character: " + char);
	}
	
	return tokens;
}

// Whitelist of valid functions
function isValidFunction(name) {
	var validFunctions = [
		'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2',
		'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
		'sind', 'cosd', 'tand',
		'log', 'ln', 'exp', 'pow',
		'sqrt', 'cbrt',
		'abs', 'floor', 'ceil', 'round', 'trunc',
		'min', 'max',
		'random'
	];
	return validFunctions.indexOf(name) !== -1;
}

// Execute whitelisted Math functions
function executeMathFunction(name, args) {
	var lower = name.toLowerCase();
	
	switch (lower) {
		// Trigonometric
		case 'sin': return Math.sin(args[0]);
		case 'cos': return Math.cos(args[0]);
		case 'tan': return Math.tan(args[0]);
		case 'asin': return Math.asin(args[0]);
		case 'acos': return Math.acos(args[0]);
		case 'atan': return Math.atan(args[0]);
		case 'atan2': return Math.atan2(args[0], args[1]);
		
		// Hyperbolic
		case 'sinh': return Math.sinh(args[0]);
		case 'cosh': return Math.cosh(args[0]);
		case 'tanh': return Math.tanh(args[0]);
		case 'asinh': return Math.asinh(args[0]);
		case 'acosh': return Math.acosh(args[0]);
		case 'atanh': return Math.atanh(args[0]);
		
		// Degree versions
		case 'sind': return Math.sin(args[0] * Math.PI / 180);
		case 'cosd': return Math.cos(args[0] * Math.PI / 180);
		case 'tand': return Math.tan(args[0] * Math.PI / 180);
		
		// Logarithmic/exponential
		case 'log': return Math.log10(args[0]);
		case 'ln': return Math.log(args[0]);
		case 'exp': return Math.exp(args[0]);
		case 'pow': return Math.pow(args[0], args[1]);
		
		// Roots
		case 'sqrt': return Math.sqrt(args[0]);
		case 'cbrt': return Math.cbrt(args[0]);
		
		// Rounding/absolute
		case 'abs': return Math.abs(args[0]);
		case 'floor': return Math.floor(args[0]);
		case 'ceil': return Math.ceil(args[0]);
		case 'round': return Math.round(args[0]);
		case 'trunc': return Math.trunc(args[0]);
		
		// Min/Max
		case 'min': return Math.min.apply(null, args);
		case 'max': return Math.max.apply(null, args);
		
		// Random
		case 'random': return Math.random();
		
		default:
			throw new Error("Unknown function: " + name);
	}
}

// Recursive descent parser
function ExpressionParser(tokens) {
	this.tokens = tokens;
	this.pos = 0;
}

ExpressionParser.prototype.parse = function() {
	var result = this.parseExpression();
	if (this.pos < this.tokens.length) {
		throw new Error("Unexpected token at position " + this.pos);
	}
	return result;
};

ExpressionParser.prototype.current = function() {
	return this.pos < this.tokens.length ? this.tokens[this.pos] : null;
};

ExpressionParser.prototype.consume = function(expectedType) {
	var token = this.current();
	if (!token || (expectedType && token.type !== expectedType)) {
		throw new Error("Expected " + expectedType + " but got " + (token ? token.type : "EOF"));
	}
	this.pos++;
	return token;
};

ExpressionParser.prototype.parseExpression = function() {
	return this.parseAdditive();
};

ExpressionParser.prototype.parseAdditive = function() {
	var result = this.parseMultiplicative();
	
	while (this.current() && this.current().type === 'OPERATOR' && (this.current().value === '+' || this.current().value === '-')) {
		var op = this.consume('OPERATOR').value;
		var right = this.parseMultiplicative();
		result = (op === '+') ? (result + right) : (result - right);
	}
	
	return result;
};

ExpressionParser.prototype.parseMultiplicative = function() {
	var result = this.parseExponential();
	
	while (this.current() && this.current().type === 'OPERATOR' && (this.current().value === '*' || this.current().value === '/' || this.current().value === '%')) {
		var op = this.consume('OPERATOR').value;
		var right = this.parseExponential();
		if (op === '*') {
			result = result * right;
		} else if (op === '/') {
			if (right === 0) {
				throw new Error("Division by zero");
			}
			result = result / right;
		} else if (op === '%') {
			result = result % right;
		}
	}
	
	return result;
};

ExpressionParser.prototype.parseExponential = function() {
	var result = this.parseUnary();
	
	if (this.current() && this.current().type === 'OPERATOR' && this.current().value === '^') {
		this.consume('OPERATOR');
		var exponent = this.parseExponential(); // Right associative
		result = Math.pow(result, exponent);
	}
	
	return result;
};

ExpressionParser.prototype.parseUnary = function() {
	if (this.current() && this.current().type === 'OPERATOR' && (this.current().value === '+' || this.current().value === '-')) {
		var op = this.consume('OPERATOR').value;
		var value = this.parseUnary();
		return (op === '-') ? (-value) : value;
	}
	
	return this.parsePrimary();
};

ExpressionParser.prototype.parsePrimary = function() {
	var token = this.current();
	
	if (!token) {
		throw new Error("Unexpected end of expression");
	}
	
	// Number literal
	if (token.type === 'NUMBER') {
		this.pos++;
		return token.value;
	}
	
	// Function call
	if (token.type === 'FUNCTION') {
		var funcName = this.consume('FUNCTION').value;
		this.consume('OPERATOR'); // (
		if (this.current().value !== '(') {
			throw new Error("Expected ( after function name");
		}
		
		var args = [];
		if (this.current() && this.current().type === 'OPERATOR' && this.current().value === '(') {
			this.pos++; // consume (
			if (this.current() && this.current().value !== ')') {
				args.push(this.parseExpression());
				while (this.current() && this.current().type === 'OPERATOR' && this.current().value === ',') {
					this.consume('OPERATOR'); // ,
					args.push(this.parseExpression());
				}
			}
			this.consume('OPERATOR'); // )
			if (this.tokens[this.pos - 1].value !== ')') {
				throw new Error("Expected )");
			}
		}
		
		return executeMathFunction(funcName, args);
	}
	
	// Parenthesized expression
	if (token.type === 'OPERATOR' && token.value === '(') {
		this.pos++;
		var result = this.parseExpression();
		token = this.consume('OPERATOR');
		if (token.value !== ')') {
			throw new Error("Expected )");
		}
		return result;
	}
	
	throw new Error("Unexpected token: " + token.type);
};

// Format result for display
function formatResult(result) {
	if (Number.isInteger(result)) {
		return result.toString();
	}

	// Handle very large or very small numbers
	if (Math.abs(result) >= 1e15 || (Math.abs(result) < 1e-6 && result !== 0)) {
		return result.toExponential(6);
	}

	// Normal decimal formatting
	return parseFloat(result.toFixed(10)).toString();
}

// Get list of available functions for help
function getAvailableFunctions() {
	return [
		// Basic arithmetic: +, -, *, /, %, ^, ()

		// Trigonometric functions
		"sin(x), cos(x), tan(x) - trigonometric functions (radians)",
		"sind(x), cosd(x), tand(x) - trigonometric functions (degrees)",
		"asin(x), acos(x), atan(x) - inverse trigonometric",
		"atan2(y, x) - two-argument arctangent",

		// Hyperbolic functions
		"sinh(x), cosh(x), tanh(x) - hyperbolic functions",
		"asinh(x), acosh(x), atanh(x) - inverse hyperbolic",

		// Logarithmic and exponential
		"log(x) - base 10 logarithm",
		"ln(x) - natural logarithm",
		"exp(x) - e^x",
		"pow(x, y) - x^y",

		// Root functions
		"sqrt(x) - square root",
		"cbrt(x) - cube root",

		// Rounding and absolute
		"abs(x) - absolute value",
		"floor(x), ceil(x), round(x), trunc(x)",

		// Min/Max/Random
		"min(a, b, ...), max(a, b, ...)",
		"random() - random number 0-1",

		// Constants
		"pi, e - mathematical constants"
	];
}
