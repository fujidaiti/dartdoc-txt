# PathSet

```dart
class PathSet extends IterableBase
    implements Set
```

Source: lib/src/path_set.dart:10:99

A set containing paths, compared using [p.equals] and [p.hash].

## Constructors

### PathSet.new({Context? context})

Source: lib/src/path_set.dart:18:18

Creates an empty [PathSet] whose contents are compared using
`context.equals` and `context.hash`.

The [context] defaults to the current path context.

```dart
PathSet({p.Context? context}) : _inner = _create(context);
```

---
### PathSet.of(Iterable other, {Context? context})

Source: lib/src/path_set.dart:26:27

Creates a [PathSet] with the same contents as [other] whose elements are
compared using `context.equals` and `context.hash`.

The [context] defaults to the current path context. If multiple elements
in [other] represent the same logical path, the first value will be
used.

```dart
PathSet.of(Iterable<String> other, {p.Context? context})
    : _inner = _create(context)..addAll(other);
```

---
## Properties

### iterator → Iterator

`@override`

A new `Iterator` that allows iterating the elements of this `Iterable`.

Iterable classes may specify the iteration order of their elements
(for example [List] always iterate in index order),
or they may leave it unspecified (for example a hash-based [Set]
may iterate in any order).

Each time `iterator` is read, it returns a new iterator,
which can be used to iterate through all the elements again.
The iterators of the same iterable can be stepped through independently,
but should return the same elements in the same order,
as long as the underlying collection isn't changed.

Modifying the collection may cause new iterators to produce
different elements, and may change the order of existing elements.
A [List] specifies its iteration order precisely,
so modifying the list changes the iteration order predictably.
A hash-based [Set] may change its iteration order completely
when adding a new element to the set.

Modifying the underlying collection after creating the new iterator
may cause an error the next time [Iterator.moveNext] is called
on that iterator.
Any *modifiable* iterable class should specify which operations will
break iteration.

---
### length → int

`@override`

The number of elements in this [Iterable].

Counting all elements may involve iterating through all elements and can
therefore be slow.
Some iterables have a more efficient way to find the number of elements.
These *must* override the default implementation of `length`.

---
## Methods

### add(String? value) → bool

Source: lib/src/path_set.dart:53:54

`@override`

Adds [value] to the set.

Returns `true` if [value] (or an equal value) was not yet in the set.
Otherwise returns `false` and the set is not changed.

Example:
```dart
final dateTimes = <DateTime>{};
final time1 = DateTime.fromMillisecondsSinceEpoch(0);
final time2 = DateTime.fromMillisecondsSinceEpoch(0);
// time1 and time2 are equal, but not identical.
assert(time1 == time2);
assert(!identical(time1, time2));
final time1Added = dateTimes.add(time1);
print(time1Added); // true
// A value equal to time2 exists already in the set, and the call to
// add doesn't change the set.
final time2Added = dateTimes.add(time2);
print(time2Added); // false

print(dateTimes); // {1970-01-01 02:00:00.000}
assert(dateTimes.length == 1);
assert(identical(time1, dateTimes.first));
print(dateTimes.length);
```

```dart
@override
bool add(String? value) => _inner.add(value);
```

---
### addAll(Iterable elements) → void

Source: lib/src/path_set.dart:56:57

`@override`

Adds all [elements] to this set.

Equivalent to adding each element in [elements] using [add],
but some collections may be able to optimize it.
```dart
final characters = <String>{'A', 'B'};
characters.addAll({'A', 'B', 'C'});
print(characters); // {A, B, C}
```

```dart
@override
void addAll(Iterable<String?> elements) => _inner.addAll(elements);
```

---
### cast<T>() → Set

Source: lib/src/path_set.dart:59:60

`@override`

A view of this iterable as an iterable of [R] instances.

If this iterable only contains instances of [R], all operations
will work correctly. If any operation tries to access an element
that is not an instance of [R], the access will throw instead.

When the returned iterable creates a new object that depends on
the type [R], e.g., from [toList], it will have exactly the type [R].

```dart
@override
Set<T> cast<T>() => _inner.cast<T>();
```

---
### clear() → void

Source: lib/src/path_set.dart:62:63

`@override`

Removes all elements from the set.
```dart
final characters = <String>{'A', 'B', 'C'};
characters.clear(); // {}
```

```dart
@override
void clear() => _inner.clear();
```

---
### contains(Object? element) → bool

Source: lib/src/path_set.dart:65:66

`@override`

Whether the collection contains an element equal to [element].

This operation will check each element in order for being equal to
[element], unless it has a more efficient way to find an element
equal to [element].
Stops iterating on the first equal element.

The equality used to determine whether [element] is equal to an element of
the iterable defaults to the [Object.==] of the element.

Some types of iterable may have a different equality used for its elements.
For example, a [Set] may have a custom equality
(see [Set.identity]) that its `contains` uses.
Likewise the `Iterable` returned by a [Map.keys] call
should use the same equality that the `Map` uses for keys.

Example:
```dart
final gasPlanets = <int, String>{1: 'Jupiter', 2: 'Saturn'};
final containsOne = gasPlanets.keys.contains(1); // true
final containsFive = gasPlanets.keys.contains(5); // false
final containsJupiter = gasPlanets.values.contains('Jupiter'); // true
final containsMercury = gasPlanets.values.contains('Mercury'); // false
```

```dart
@override
bool contains(Object? element) => _inner.contains(element);
```

---
### containsAll(Iterable other) → bool

Source: lib/src/path_set.dart:68:69

`@override`

Whether this set contains all the elements of [other].
```dart
final characters = <String>{'A', 'B', 'C'};
final containsAB = characters.containsAll({'A', 'B'});
print(containsAB); // true
final containsAD = characters.containsAll({'A', 'D'});
print(containsAD); // false
```

```dart
@override
bool containsAll(Iterable<Object?> other) => _inner.containsAll(other);
```

---
### difference(Set other) → Set

Source: lib/src/path_set.dart:71:72

`@override`

Creates a new set with the elements of this that are not in [other].

That is, the returned set contains all the elements of this [Set] that
are not elements of [other] according to `other.contains`.
```dart
final characters1 = <String>{'A', 'B', 'C'};
final characters2 = <String>{'A', 'E', 'F'};
final differenceSet1 = characters1.difference(characters2);
print(differenceSet1); // {B, C}
final differenceSet2 = characters2.difference(characters1);
print(differenceSet2); // {E, F}
```

```dart
@override
Set<String?> difference(Set<Object?> other) => _inner.difference(other);
```

---
### intersection(Set other) → Set

Source: lib/src/path_set.dart:74:75

`@override`

Creates a new set which is the intersection between this set and [other].

That is, the returned set contains all the elements of this [Set] that
are also elements of [other] according to `other.contains`.
```dart
final characters1 = <String>{'A', 'B', 'C'};
final characters2 = <String>{'A', 'E', 'F'};
final intersectionSet = characters1.intersection(characters2);
print(intersectionSet); // {A}
```

```dart
@override
Set<String?> intersection(Set<Object?> other) => _inner.intersection(other);
```

---
### lookup(Object? element) → String?

Source: lib/src/path_set.dart:77:78

`@override`

If an object equal to [object] is in the set, return it.

Checks whether [object] is in the set, like [contains], and if so,
returns the object in the set, otherwise returns `null`.

If the equality relation used by the set is not identity,
then the returned object may not be *identical* to [object].
Some set implementations may not be able to implement this method.
If the [contains] method is computed,
rather than being based on an actual object instance,
then there may not be a specific object instance representing the
set element.
```dart
final characters = <String>{'A', 'B', 'C'};
final containsB = characters.lookup('B');
print(containsB); // B
final containsD = characters.lookup('D');
print(containsD); // null
```

```dart
@override
String? lookup(Object? element) => _inner.lookup(element);
```

---
### remove(Object? value) → bool

Source: lib/src/path_set.dart:80:81

`@override`

Removes [value] from the set.

Returns `true` if [value] was in the set, and `false` if not.
The method has no effect if [value] was not in the set.
```dart
final characters = <String>{'A', 'B', 'C'};
final didRemoveB = characters.remove('B'); // true
final didRemoveD = characters.remove('D'); // false
print(characters); // {A, C}
```

```dart
@override
bool remove(Object? value) => _inner.remove(value);
```

---
### removeAll(Iterable elements) → void

Source: lib/src/path_set.dart:83:84

`@override`

Removes each element of [elements] from this set.
```dart
final characters = <String>{'A', 'B', 'C'};
characters.removeAll({'A', 'B', 'X'});
print(characters); // {C}
```

```dart
@override
void removeAll(Iterable<Object?> elements) => _inner.removeAll(elements);
```

---
### removeWhere(Function test) → void

Source: lib/src/path_set.dart:86:87

`@override`

Removes all elements of this set that satisfy [test].
```dart
final characters = <String>{'A', 'B', 'C'};
characters.removeWhere((element) => element.startsWith('B'));
print(characters); // {A, C}
```

```dart
@override
void removeWhere(bool Function(String?) test) => _inner.removeWhere(test);
```

---
### retainAll(Iterable elements) → void

Source: lib/src/path_set.dart:89:90

`@override`

Removes all elements of this set that are not elements in [elements].

Checks for each element of [elements] whether there is an element in this
set that is equal to it (according to `this.contains`), and if so, the
equal element in this set is retained, and elements that are not equal
to any element in [elements] are removed.
```dart
final characters = <String>{'A', 'B', 'C'};
characters.retainAll({'A', 'B', 'X'});
print(characters); // {A, B}
```

```dart
@override
void retainAll(Iterable<Object?> elements) => _inner.retainAll(elements);
```

---
### retainWhere(Function test) → void

Source: lib/src/path_set.dart:92:93

`@override`

Removes all elements of this set that fail to satisfy [test].
```dart
final characters = <String>{'A', 'B', 'C'};
characters.retainWhere(
    (element) => element.startsWith('B') || element.startsWith('C'));
print(characters); // {B, C}
```

```dart
@override
void retainWhere(bool Function(String?) test) => _inner.retainWhere(test);
```

---
### union(Set other) → Set

Source: lib/src/path_set.dart:95:96

`@override`

Creates a new set which contains all the elements of this set and [other].

That is, the returned set contains all the elements of this [Set] and
all the elements of [other].
```dart
final characters1 = <String>{'A', 'B', 'C'};
final characters2 = <String>{'A', 'E', 'F'};
final unionSet1 = characters1.union(characters2);
print(unionSet1); // {A, B, C, E, F}
final unionSet2 = characters2.union(characters1);
print(unionSet2); // {A, E, F, B, C}
```

```dart
@override
Set<String?> union(Set<String?> other) => _inner.union(other);
```

---
### toSet() → Set

Source: lib/src/path_set.dart:98:99

`@override`

Creates a [Set] containing the same elements as this iterable.

The set may contain fewer elements than the iterable,
if the iterable contains an element more than once,
or it contains one or more elements that are equal.
The order of the elements in the set is not guaranteed to be the same
as for the iterable.

Example:
```dart
final planets = <int, String>{1: 'Mercury', 2: 'Venus', 3: 'Mars'};
final valueSet = planets.values.toSet(); // {Mercury, Venus, Mars}
```

```dart
@override
Set<String?> toSet() => _inner.toSet();
```

---
