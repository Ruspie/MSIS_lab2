var Native = function(options){
  options = options || {};
  var legacy = options.legacy;
  var protect = options.protect;
  var methods = options.implement;
  var generics = options.generics;
  var initialize = options.initialize;
  var object = initialize || legacy;
  generics = generics !== false;

  object.constructor = Native;
  object.$family = {name: 'native'};
  if (legacy && initialize) object.prototype = legacy.prototype;
  object.prototype.constructor = object;

  var add = function(obj, name, method, force){
    if (!protect || force || !obj.prototype[name]) obj.prototype[name] = method;
    if (generics) Native.genericize(obj, name, protect);
    return obj;
  };

  object.implement = function(a1, a2, a3){
    if (typeof a1 == 'string') return add(this, a1, a2, a3);
    for (var p in a1) add(this, p, a1[p], a2);
    return this;
  };

  if (methods) object.implement(methods);

  return object;
};

Native.genericize = function(object, property, check){
  if ((!check || !object[property]) && typeof object.prototype[property] == 'function') object[property] = function(){
    var args = Array.prototype.slice.call(arguments);
    return object.prototype[property].apply(args.shift(), args);
  };
};

Native.implement = function(objects, properties){
  for (var i = 0, l = objects.length; i < l; i++) objects[i].implement(properties);
};

Native.typize = function(object, family){
  if (!object.type) object.type = function(item){
    return ($type(item) === family);
  };
};

(function(){
  var natives = {'Array': Array, 'Date': Date, 'Function': Function, 'Number': Number, 'RegExp': RegExp, 'String': String};
  for (var n in natives) new Native({name: n, initialize: natives[n], protect: true});

  var types = {'boolean': Boolean, 'native': Native, 'object': Object};
  for (var t in types) Native.typize(types[t], t);

  var generics = {'Array': ["slice"]};
  for (var g in generics){
    for (var i = generics[g].length; i--;) Native.genericize(natives[g], generics[g][i], true);
  }
})();

function $clear(timer){
  clearTimeout(timer);
  clearInterval(timer);
  return null;
}

function $mixin(mix){
  for (var i = 1, l = arguments.length; i < l; i++){
    var object = arguments[i];
    if ($type(object) != 'object') continue;
    for (var key in object){
      var op = object[key], mp = mix[key];
      mix[key] = (mp && $type(op) == 'object' && $type(mp) == 'object') ? $mixin(mp, op) : $unlink(op);
    }
  }
  return mix;
}

var $time = Date.now || function(){
  return +new Date();
};

function $type(obj){
  if (obj === undefined) {
    return false;
  }
  return typeof obj;
}

function $unlink(object){
  var unlinked;
  if ($type(object) === "object") {
    unlinked = {};
    for (var p in object) unlinked[p] = $unlink(object[p]);
  } else{
    return object;
  }
  return unlinked;
}

Number.implement({

  round: function(precision){
    precision = Math.pow(10, precision || 0);
    return Math.round(this * precision) / precision;
  }

});

delete Function.prototype.bind;

Function.implement({

  extend: function(properties){
    for (var property in properties) this[property] = properties[property];
    return this;
  },

  create: function(options){
    var self = this;
    options = options || {};
    return function(event){
      var args,
      returns = function(){
        return self.apply(options.bind || null, args);
      };
      if (options.periodical) return setInterval(returns, options.periodical);
      return returns();
    };
  },

  periodical: function(periodical, bind, args){
    return this.create({bind: bind, periodical: periodical})();
  }

});

function Class(params){
  
  var newClass = function(){
    this._current = {};
    var value = (this.initialize) ? this.initialize.apply(this, arguments) : this;
    delete this._current; delete this.caller;
    return value;
  }.extend(this);
  
  newClass.implement(params);
  return newClass;
}

new Native({name: 'Class', initialize: Class}).extend({
  
  wrap: function(self, key, method){
    return function(){
      var caller = this.caller, current = this._current;
      this.caller = current; this._current = arguments.callee;
      var result = method.apply(this, arguments);
      this._current = current; this.caller = caller;
      return result;
    }.extend({_owner: self, _origin: method, _name: key});
  }
});

Class.implement({
  implement: function(key, value){
    
    if ($type(key) == 'object'){
      for (var p in key) this.implement(p, key[p]);
      return this;
    }
    var proto = this.prototype;

    switch ($type(value)){
      
      case 'function':
        if (value._hidden) return this;
        proto[key] = Class.wrap(this, key, value);
      break;
      
      case 'object':
        var previous = proto[key];
        if ($type(previous) == 'object') $mixin(previous, value);
        else proto[key] = $unlink(value);
      break;
      default: proto[key] = value;
    }
    return this;
  }
});

CashRegister = new Class({
  $chain: [],
  options: {
    precision: 2,
    prefix: '$',
    thousandsSeparator: ',',
    decimalSeparator: '.',
    fps: 50,
    unit: false,
    duration: 500
	},
  
  initialize: function(element, options){
    this.element = this.subject = document.getElementById("total");
  },

  callChain: function(){
    return (this.$chain.length) ? this.$chain.shift().apply(this, arguments) : false;
  },

  getTransition: function(){
    return function(p){
      return -(Math.cos(Math.PI * p) - 1) / 2;
    };
  },

  fireEvent: function(type, args, delay){
    type = CashRegister.removeOn(type);
    if (!this.$events || !this.$events[type]) return this;
    this.$events[type].each(function(fn){
      fn.create({'bind': this, 'delay': delay, 'arguments': args})();
    }, this);
    return this;
  },

  step: function(){
    var time = $time();
    if (time < this.time + this.options.duration){
      var delta = this.transition((time - this.time) / this.options.duration);
      this.set(this.compute(this.from, this.to, delta));
    } else {
      this.set(this.compute(this.from, this.to, 1));
      this.complete();
    }
  },

  compute: function(from, to, delta){
    return CashRegister.compute(from, to, delta);
  },

  check: function(){
    if (!this.timer) return true;
    switch (this.options.link){
      case 'cancel': this.cancel(); return true;
      case 'chain': this.chain(this.caller.bind(this, arguments)); return false;
    }
    return false;
  },

  complete: function(){
    if (this.stopTimer()) this.onComplete();
    return this;
  },

  cancel: function(){
    if (this.stopTimer()) this.onCancel();
    return this;
  },

  onStart: function(){
    this.fireEvent('start', this.subject);
  },

  onComplete: function(){
    this.fireEvent('complete', this.subject);
    if (!this.callChain()) this.fireEvent('chainComplete', this.subject);
  },

  onCancel: function(){
    this.fireEvent('cancel', this.subject).clearChain();
  },

  pause: function(){
    this.stopTimer();
    return this;
  },

  resume: function(){
    this.startTimer();
    return this;
  },

  stopTimer: function(){
    if (!this.timer) return false;
    this.time = $time() - this.time;
    this.timer = $clear(this.timer);
    return true;
  },

  startTimer: function(){
    if (this.timer) return false;
    this.time = $time() - this.time;
    this.timer = this.step.periodical(Math.round(1000 / this.options.fps), this);
    return true;
  },
  
  start: function(to){
    if (!this.check(to)) return this;
    
    var current_value = this.element.innerHTML;
    current_value = current_value.substring(this.options.prefix.length);
    current_value = this.stripSeparators(current_value);
    current_value = parseFloat(current_value).round(this.options.precision);
    
    this.from = current_value;
    this.to = to;
    this.time = 0;
		this.transition = this.getTransition();
		this.startTimer();
		this.onStart();

		return this;
  },
  
  set: function(now){
    var new_value = this.options.prefix + now.round(this.options.precision);
    
    this.element.innerHTML =  this.addSeparators(new_value);
  },
  
  addSeparators: function(number)
  {
    var parts = number.toString().split(this.options.decimalSeparator),
      cents;
    var dollars = parts[0];
    if (parts[1]) {
      cents = parts[1];
    }

    var rgx = /(\d+)(\d{3})/;
    while (rgx.test(dollars)) {
      dollars = dollars.replace(rgx, '$1' + this.options.thousandsSeparator + '$2');
    }
    var output = dollars;

    if (this.options.precision > 0) {
      if (cents) {
        output += this.options.decimalSeparator + cents;
      } else {
        output += '0' * this.options.precision;
      }
    }
    return output;
  },
  
  stripSeparators: function(string) {
    var result = string.replace(this.options.decimalSeparator, '.');
    var pattern = new RegExp(this.options.thousandsSeparator, 'g');
    var matches = result.match(pattern);
    
    if (matches) {
      matches.each(function() {
        result = string.replace(pattern, '');
      });
    }
    
    return result;
  }
});

CashRegister.removeOn = function(string){
  return string.replace(/^on([A-Z])/, function(full, first){
    return first.toLowerCase();
  });
};
CashRegister.compute = function(from, to, delta){
  return (to - from) * delta + from;
};