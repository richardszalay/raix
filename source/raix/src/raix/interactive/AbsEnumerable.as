package raix.interactive
{
	import flash.errors.IllegalOperationError;
	import flash.utils.Dictionary;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import raix.reactive.ICancelable;
	import raix.reactive.IObservable;
	import raix.reactive.IObserver;
	import raix.reactive.Observable;
	import raix.reactive.scheduling.IScheduler;
	import raix.reactive.scheduling.Scheduler;
	
	public class AbsEnumerable extends Proxy implements IEnumerable
	{
		private var _currentEnumerator : IEnumerator;
		private var _currentIndex : int = 0;
		
		public function AbsEnumerable()
		{
		}
		
		public function any(predicate : Function = null) : Boolean
		{
			for each(var value : Object in this)
			{
				if (predicate == null)
				{
					return true;
				}
				else
				{
					if (predicate(value))
					{
						return true;
					}
				}
			}
			
			return false;
		}
		
		public function all(predicate : Function) : Boolean
		{
			if (predicate == null)
			{
				throw new ArgumentError("predicate cannot be null");
			}
			
			for each(var value : Object in this)
			{
				if (!predicate(value))
				{
					return false;
				}
			}
			
			return true;
		}
		
		public function first(predicate : Function = null) : Object
		{
			for each(var value : Object in this)
			{
				if (predicate == null || predicate(value))
				{
					return value;
				}
			}
			
			throw new IllegalOperationError("No matching items found");
		}
		
		public function firstOrDefault(defaultValue : Object = null, predicate : Function = null) : Object
		{
			for each(var value : Object in this)
			{
				if (predicate == null || predicate(value))
				{
					return value;
				}
			}
			
			return defaultValue;
		}
		
		public function single(predicate : Function = null) : Object
		{
			var matchedAny : Boolean = false;
			var matchedValue : Object = null;
			
			for each(var value : Object in this)
			{
				if (predicate == null || predicate(value))
				{
					if (matchedAny)
					{
						throw new IllegalOperationError("Sequence contained multiple elements");
					}
					else
					{
						matchedAny = true;
						matchedValue = value;
					}
				}
			}
			
			if (matchedAny)
			{
				return matchedValue;
			}
			
			throw new IllegalOperationError("No matching items found");
		}
		
		public function singleOrDefault(defaultValue : Object = null, predicate : Function = null) : Object
		{
			var matchedAny : Boolean = false;
			var matchedValue : Object = null;
			
			for each(var value : Object in this)
			{
				if (predicate == null || predicate(value))
				{
					if (matchedAny)
					{
						throw new IllegalOperationError("Sequence contained multiple elements");
					}
					else
					{
						matchedAny = true;
						matchedValue = value;
					}
				}
			}
			
			if (matchedAny)
			{
				return matchedValue;
			}
			
			return defaultValue;
		}
		
		public function last(predicate : Function = null) : Object
		{
			var matchedAny : Boolean = false;
			var matchedValue : Object = null;
			
			for each(var value : Object in this)
			{
				if (predicate == null || predicate(value))
				{
					matchedAny = true;
					matchedValue = value;
				}
			}
			
			if (matchedAny)
			{
				return matchedValue;
			}
			
			throw new IllegalOperationError("No matching items found");
		}
		
		public function lastOrDefault(defaultValue : Object = null, predicate : Function = null) : Object
		{
			var matchedAny : Boolean = false;
			var matchedValue : Object = null;
			
			for each(var value : Object in this)
			{
				if (predicate == null || predicate(value))
				{
					matchedAny = true;
					matchedValue = value;
				}
			}
			
			if (matchedAny)
			{
				return matchedValue;
			}
			
			return defaultValue;
		}
		
		public function aggregate(seed : Object, accumulator : Function, resultSelector : Function = null) : Object
		{
			var lastScanResult : Object = this.scan(seed, accumulator, null).lastOrDefault(seed);
			
			return resultSelector == null
				? lastScanResult
				: resultSelector(lastScanResult);
		}
		
		public function scan(seed : Object, accumulator : Function, resultSelector : Function = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var accumulate : Object = seed;
				var currentValue : Object = null;
				
				var innerEnumerator : IEnumerator = source.getEnumerator();
				
				return new ClosureEnumerator(function():Boolean
				{
					if (innerEnumerator.moveNext())
					{
						accumulate = accumulator(accumulate, innerEnumerator.current);
						
						currentValue = (resultSelector == null)
							? accumulate
							: resultSelector(accumulate);
						
						return true;
					}
					
					return false;
					
				}, function():Object { return currentValue; });
			});
		}
		
		public function distinct(hashSelector : Function = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var hashSet : Dictionary = new Dictionary();
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					while (innerEnumerator.moveNext())
					{
						var hash : Object = (hashSelector == null)
							? innerEnumerator.current
							: hashSelector(innerEnumerator.current);
							
						if (hashSet[hash] === undefined)
						{
							hashSet[hash] = true;
							return true;
						}
					}
					
					return false;
					
				}, function():Object { return innerEnumerator.current; });
			});
		}
		
		public function union(right : IEnumerable, hashSelector : Function = null) : IEnumerable
		{
			return this.concat(right).distinct(hashSelector);
		}
		
		public function intersect(right : IEnumerable, hashSelector : Function = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var hashSet : Dictionary = new Dictionary();
				var innerEnumerator : IEnumerator = source.getEnumerator();
				
				for each(var rightValue : Object in right)
				{
					var hash : Object = (hashSelector == null)
						? rightValue
						: hashSelector(rightValue);
						
					if (hashSet[hash] === undefined)
					{
						hashSet[hash] = true;
					}
				} 
				
				return new ClosureEnumerator(function():Boolean
				{
					while (innerEnumerator.moveNext())
					{
						var hash : Object = (hashSelector == null)
							? innerEnumerator.current
							: hashSelector(innerEnumerator.current);
							
						if (hashSet[hash] == true)
						{
							delete hashSet[hash];
							return true;
						}
					}
					
					return false;
					
				}, function():Object { return innerEnumerator.current; });
			});
		}
		
		public function except(right : IEnumerable, hashSelector : Function = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var hashSet : Dictionary = new Dictionary();
				var innerEnumerator : IEnumerator = source.getEnumerator();
				
				for each(var rightValue : Object in right)
				{
					var hash : Object = (hashSelector == null)
						? rightValue
						: hashSelector(rightValue);
						
					if (hashSet[hash] === undefined)
					{
						hashSet[hash] = true;
					}
				} 
				
				return new ClosureEnumerator(function():Boolean
				{
					while (innerEnumerator.moveNext())
					{
						var hash : Object = (hashSelector == null)
							? innerEnumerator.current
							: hashSelector(innerEnumerator.current);
							
						if (hashSet[hash] === undefined)
						{
							hashSet[hash] = true;
							return true;
						}
					}
					
					return false;
					
				}, function():Object { return innerEnumerator.current; });
			});
		}
		
		public function defaultIfEmpty(defaultValue : Object = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var isFirst : Boolean = true;
				var usedDefault : Boolean = false;
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					if (usedDefault)
					{
						return false;
					}
					
					if (!innerEnumerator.moveNext())
					{
						if (isFirst)
						{
							usedDefault = true;
							return true;
						}
						
						return false;
					}
					
					isFirst = false;
					return true;
					
				}, function():Object
				{
					if (usedDefault)
					{
						return defaultValue;
					}
					
					return innerEnumerator.current;
				});
			});
		}
		
		public function toLookup(keySelector : Function, elementSelector : Function = null, 
			keyHashSelector : Function = null) : ILookup
		{
			if (keySelector == null)
			{
				throw new ArgumentError("keySelector cannot be null");
			}
			
			var lookup : Lookup = new Lookup(keyHashSelector);
			
			var hasElementSelector : Boolean = (elementSelector != null);
			
			for each(var item : Object in this)
			{
				var key : Object = keySelector(item);
				
				var element : Object = hasElementSelector
					? elementSelector(item)
					: item;
					
				lookup.add(key, element);
			}
			
			return lookup;
		}
		
		public function toDictionary(keySelector : Function, elementSelector : Function = null) : Dictionary
		{
			var dictionary : Dictionary = new Dictionary();
			
			for each(var value : Object in this)
			{
				var key : Object = keySelector(value);
				var element : Object = (elementSelector != null)
					? elementSelector(value)
					: value; 
					
				if (key == null)
				{
					throw new ArgumentError("Key cannot be null");
				}
					
				if (dictionary[key] !== undefined)
				{
					throw new ArgumentError("Duplicate key defined: " + key);
				}
				
				dictionary[key] = element;
			}
			
			return dictionary
		}
		
		public function join(inner : IEnumerable, outerKeySelector : Function, innerKeySelector : Function, 
			resultSelector : Function, keyHashSelector : Function = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var innerLookup : ILookup = inner.toLookup(innerKeySelector, null, keyHashSelector);
				
				var outerEnumerator : IEnumerator = source.getEnumerator();
				var innerEnumerator : IEnumerator = null; 
				var currentValue : Object;
				
				return new ClosureEnumerator(function():Boolean
				{
					do
					{
						if (innerEnumerator != null)
						{
							if (innerEnumerator.moveNext())
							{
								currentValue = resultSelector(
									outerEnumerator.current,
									innerEnumerator.current);
								
								return true;
							}
							else
							{
								innerEnumerator = null;
							}
						}
						
						if (outerEnumerator.moveNext())
						{
							var outerKey : Object = outerKeySelector(outerEnumerator.current);
							
							innerEnumerator = innerLookup.getValues(outerKey).getEnumerator();
						}
					}
					while (innerEnumerator != null);
					
					return false;
				},
				function():Object { return currentValue; });
			});
		}
		
		public function groupJoin(inner : IEnumerable, outerKeySelector : Function, innerKeySelector : Function, 
			resultSelector : Function, keyHashSelector : Function = null) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var innerLookup : ILookup = inner.toLookup(innerKeySelector, null, keyHashSelector);
				
				var outerEnumerator : IEnumerator = source.getEnumerator();
				var currentValue : Object;
				
				return new ClosureEnumerator(function():Boolean
				{
					if (outerEnumerator.moveNext())
					{
						var outerKey : Object = outerKeySelector(outerEnumerator.current);
						
						var values : IEnumerable = innerLookup.getValues(outerKey);
						
						currentValue = resultSelector(outerEnumerator.current, values);
						
						return true;
					}
					
					return false;
				},
				function():Object { return currentValue; });
			});
		}
		
		public function groupBy(keySelector : Function, elementSelector : Function = null, 
			keyHashSelector : Function = null) : IEnumerable
		{
			return toLookup(keySelector, elementSelector, keyHashSelector);			
		}
		
		public function take(count : uint) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var currentCount : int = 0;
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					return (currentCount++ < count) && innerEnumerator.moveNext(); 
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function takeLast(count : uint) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var array : Array = source.toArray();
				var actualCount : uint = Math.min(count, array.length);
				
				array = array.slice(array.length - actualCount, array.length);
				
				return Enumerable.fromArray(array).getEnumerator();
			});
		}
		
		public function takeWhile(predicate : Function) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					if (innerEnumerator.moveNext() && 
						predicate(innerEnumerator.current))
					{
						return true;
					}
					
					return false;
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function skip(count : uint) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var remaining : uint = count;
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					while(remaining > 0 && innerEnumerator.moveNext())
					{
						remaining--;
					}
					
					return innerEnumerator.moveNext();
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function skipLast(count : uint) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var array : Array = source.toArray();
				var actualCount : uint = Math.max(0, array.length - count);
				
				if (actualCount > 0)
				{
					array = array.slice(0, actualCount);
				
					return Enumerable.fromArray(array).getEnumerator();
				}
				else
				{
					return Enumerable.empty().getEnumerator();					
				}
			});
		}
		
		public function skipWhile(predicate : Function) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var isSkipping : Boolean = true;
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					if (isSkipping)
					{
						while (innerEnumerator.moveNext())
						{
							if (!predicate(innerEnumerator.current))
							{
								isSkipping = false;
								break;
							}
						}
						
						return !isSkipping;
					}
					
					return innerEnumerator.moveNext();
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function concat(other : IEnumerable) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var isFirst : Boolean = true;
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					if (!innerEnumerator.moveNext())
					{
						if (isFirst)
						{
							isFirst = false;
							innerEnumerator = other.getEnumerator();
							
							return innerEnumerator.moveNext();
						}
						else
						{
							return false;
						}
					}
					
					return true;
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function zip(right : IEnumerable, resultSelector : Function) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var leftEnumerator : IEnumerator = source.getEnumerator();
				var rightEnumerator : IEnumerator = right.getEnumerator();
				var currentValue : Object = null;
				
				return new ClosureEnumerator(function():Boolean
				{
					if (leftEnumerator.moveNext() &&
						rightEnumerator.moveNext())
					{
						currentValue = resultSelector(
							leftEnumerator.current,
							rightEnumerator.current);
							
						return true;
					}
					else
					{
						return false;
					}
				},
				function() : Object { return currentValue; });
			});
		}
		
		public function sequenceEqual(right : IEnumerable, comparer : Function = null) : Boolean
		{
			return this.zip(right, function(l:Object, r:Object) : Boolean
			{
				return (comparer == null)
					? l == r
					: comparer(l,r);
			})
			.all(function(v:Boolean):Boolean { return v; });
		}
		
		public function map(selector : Function) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var innerEnumerator : IEnumerator = source.getEnumerator();
				
				var currentValue : Object = null; 
				
				return new ClosureEnumerator(function():Boolean
				{
					if (innerEnumerator.moveNext())
					{
						currentValue = selector(innerEnumerator.current);
						return true;
					} 
					else
					{
						return false;
					}
				},
				function():Object { return currentValue; });
			});
		}
		
		public function mapMany(collectionSelector : Function, resultSelector : Function = null) : IEnumerable
		{
			if (collectionSelector == null)
			{
				throw new ArgumentError("collectionSelector cannot be null");
			}
			
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var leftEnumerator : IEnumerator = source.getEnumerator();
				var rightEnumerator : IEnumerator = null; 
				
				var currentValue : Object = null;
				var leftIndex : int = -1;
				
				var rightMoveNext : Function = function():Boolean
				{
					if (rightEnumerator.moveNext())
					{
						if (resultSelector != null)
						{
							currentValue = resultSelector(
								leftEnumerator.current,
								rightEnumerator.current);
						}
						else
						{
							currentValue = rightEnumerator.current;
						}
						
						return true;
					}
					
					rightEnumerator = null;
						
					return false;
				};
				
				return new ClosureEnumerator(function():Boolean
				{
					if (rightEnumerator != null && rightMoveNext())
					{
						return true;
					}
					
					while (leftEnumerator.moveNext())
					{
						rightEnumerator = IEnumerable(collectionSelector(
							leftEnumerator.current, ++leftIndex)).getEnumerator();
						
						if (rightMoveNext())
						{
							return true;
						}
					} 
					
					return false;
				},
				function():Object { return currentValue; });
			});
		}
		
		public function filter(predicate : Function) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					while(innerEnumerator.moveNext())
					{
						if (predicate(innerEnumerator.current))
						{
							return true;
						}
					}
					
					return false;
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function ofType(cls : Class) : IEnumerable
		{
			return filter(function(v:Object) : Boolean
			{
				return v is cls;
			});
		}
		
		public function repeat(count : uint = 0) : IEnumerable
		{
			var source : IEnumerable = this;
			
			return new ClosureEnumerable(function():IEnumerator
			{
				var repetitionsRemaining : uint = count;
				var innerEnumerator : IEnumerator = source.getEnumerator(); 
				
				return new ClosureEnumerator(function():Boolean
				{
					if (!innerEnumerator.moveNext())
					{
						if (count == 0 || --repetitionsRemaining > 0)
						{
							innerEnumerator = source.getEnumerator();
							
							return innerEnumerator.moveNext();
						}
						else
						{
							return false;
						}
					}
					
					return true;
				},
				function():Object { return innerEnumerator.current; });
			});
		}
		
		public function orderBy(keySelector : Function, comparer : Function = null) : IOrderedEnumerable
		{
			return new OrderedEnumerable(this, 
				Comparer.projection(keySelector, comparer || Comparer.defaultComparer));
		}
		
		public function orderByDescending(keySelector : Function, comparer : Function = null) : IOrderedEnumerable
		{
			var sourceComparer : Function = Comparer.projection(keySelector, 
				comparer || Comparer.defaultComparer);
				
			return new OrderedEnumerable(this,
				Comparer.reverse(sourceComparer));
		}
		
		public function count() : uint
		{
			var count : uint = 0;
			
			for each(var val : Object in this)
			{
				count++;
			} 
			
			return count;
		}
		
		public function toObservable(scheduler : IScheduler = null) : IObservable
		{
			scheduler = scheduler || Scheduler.asynchronous;
			
			var source : IEnumerable = this;
			
			return Observable.createWithCancelable(Object, function(observer : IObserver) : ICancelable
			{
				var enumerator : IEnumerator = source.getEnumerator(); 
				
				return Scheduler.scheduleRecursive(scheduler, function(reschedule : Function) : void
				{
					var valueAvailable : Boolean;
							
					try
					{
						valueAvailable = enumerator.moveNext();
					}
					catch(error : Error)
					{
						observer.onError(error);
						return;
					}
					
					if (valueAvailable)
					{
						observer.onNext(enumerator.current);
						
						reschedule();
					}
					else
					{
						observer.onCompleted();
					}
				});
			});
		}
		
		public function toArray() : Array
		{
			var output : Array = new Array();
			
			for each(var value : Object in this)
			{
				output.push(value);
			}
			
			return output;
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			if (index == 0)
            {
            	reset();
            	
            	_currentEnumerator = getEnumerator();
            }
            else
            {
            	if (_currentIndex != index)
            	{
            		throw new IllegalOperationError("Parallel enumerations are not supported");
            	}
            }
            
            if (_currentEnumerator.moveNext())
            {
            	_currentIndex = index+1;
            	
            	return _currentIndex;
            }
            else
            {
            	reset();
            	
            	return 0;
            }
		}
		
		override flash_proxy function nextValue(index:int):*
		{
            return _currentEnumerator.current;
        }
		
        public function cancel() : void
        {
        	
        }
		
		public function getEnumerator() : IEnumerator
		{
			throw new IllegalOperationError("abstract method getEnumerator not implemented");
		}
		
		private function reset() : void
        {
        	_currentEnumerator = null;
        	_currentIndex = 0;
        }
	}
}