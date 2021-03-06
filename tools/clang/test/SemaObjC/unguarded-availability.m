// RUN: %clang_cc1 -triple x86_64-apple-macosx-10.9 -Wunguarded-availability -fblocks -fsyntax-only -verify %s
// RUN: %clang_cc1 -xobjective-c++ -std=c++11 -DOBJCPP -triple x86_64-apple-macosx-10.9 -Wunguarded-availability -fblocks -fsyntax-only -verify %s

#define AVAILABLE_10_0  __attribute__((availability(macos, introduced = 10.0)))
#define AVAILABLE_10_11 __attribute__((availability(macos, introduced = 10.11)))
#define AVAILABLE_10_12 __attribute__((availability(macos, introduced = 10.12)))

typedef int AVAILABLE_10_12 new_int; // expected-note + {{marked partial here}}

int func_10_11() AVAILABLE_10_11; // expected-note 4 {{'func_10_11' has been explicitly marked partial here}}

#ifdef OBJCPP
// expected-note@+2 6 {{marked partial here}}
#endif
int func_10_12() AVAILABLE_10_12; // expected-note 7 {{'func_10_12' has been explicitly marked partial here}}

int func_10_0() AVAILABLE_10_0;

void use_func() {
  func_10_11(); // expected-warning{{'func_10_11' is only available on macOS 10.11 or newer}} expected-note{{enclose 'func_10_11' in an @available check to silence this warning}}

  if (@available(macos 10.11, *))
    func_10_11();
  else
    func_10_11(); // expected-warning{{'func_10_11' is only available on macOS 10.11 or newer}} expected-note{{enclose 'func_10_11' in an @available check to silence this warning}}
}

void defn_10_11() AVAILABLE_10_11;

void defn_10_11() {
  func_10_11();
}

void nested_ifs() {
  if (@available(macos 10.12, *)) {
    if (@available(macos 10.10, *)) {
      func_10_12();
    } else {
      func_10_12();
    }
  } else {
    func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{enclose 'func_10_12' in an @available check to silence this warning}}
  }
}

void star_case() {
  if (@available(ios 9, *)) {
    func_10_11(); // expected-warning{{'func_10_11' is only available on macOS 10.11 or newer}} expected-note{{enclose 'func_10_11' in an @available check to silence this warning}}
    func_10_0();
  } else
    func_10_11(); // expected-warning{{'func_10_11' is only available on macOS 10.11 or newer}} expected-note{{enclose 'func_10_11' in an @available check to silence this warning}}

  if (@available(macOS 10.11, *)) {
    if (@available(ios 8, *)) {
      func_10_11();
      func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{enclose}}
    } else {
      func_10_11();
      func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{enclose}}
    }
  }
}

typedef int int_10_11 AVAILABLE_10_11; // expected-note {{'int_10_11' has been explicitly marked partial here}}
#ifdef OBJCPP
// expected-note@+2 {{marked partial here}}
#endif
typedef int int_10_12 AVAILABLE_10_12; // expected-note 2 {{'int_10_12' has been explicitly marked partial here}}

void use_typedef() {
  int_10_11 x; // expected-warning{{'int_10_11' is only available on macOS 10.11 or newer}} expected-note{{enclose 'int_10_11' in an @available check to silence this warning}}
}

__attribute__((objc_root_class))
AVAILABLE_10_11 @interface Class_10_11 { // expected-note{{annotate 'Class_10_11' with an availability attribute to silence}}
  int_10_11 foo;
  int_10_12 bar; // expected-warning {{'int_10_12' is partial: introduced in macOS 10.12}}
}
- (void)method1;
- (void)method2;
@end

@implementation Class_10_11
- (void) method1 {
  func_10_11();
  func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{enclose 'func_10_12' in an @available check to silence this warning}}
}

- (void)method2 AVAILABLE_10_12 {
  func_10_12();
}

@end

int protected_scope() {
  if (@available(macos 10.20, *)) { // expected-note 2 {{jump enters controlled statement of if available}}
  label1:
    return 0;
  } else {
  label2:
    goto label1; // expected-error{{cannot jump from this goto statement to its label}}
  }

  goto label2; // expected-error{{cannot jump from this goto statement to its label}}
}

struct S {
  int m1;
  int m2 __attribute__((availability(macos, introduced = 10.12))); // expected-note{{marked partial here}}

  struct Nested {
    int nested_member __attribute__((availability(macos, introduced = 10.12))); // expected-note{{marked partial here}}
  } n;
};

int test_members() {
  struct S s;
  (void)s.m1;
  (void)s.m2; // expected-warning{{'m2' is only available on macOS 10.12 or newer}} expected-note{{@available}}

  (void)s.n.nested_member; // expected-warning{{'nested_member' is only available on macOS 10.12 or newer}} expected-note{{@available}}
}

void test_blocks() {
  (void) ^{
    func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  };
}

void test_params(int_10_12 x); // expected-warning {{'int_10_12' is partial: introduced in macOS 10.12}} expected-note{{annotate 'test_params' with an availability attribute to silence}}

void test_params2(int_10_12 x) AVAILABLE_10_12; // no warn

void (^topLevelBlockDecl)() = ^ {
  func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  if (@available(macos 10.12, *))
    func_10_12();
};

AVAILABLE_10_12
__attribute__((objc_root_class))
@interface InterWithProp // expected-note 2 {{marked partial here}}
@property(class) int x;
+ (void) setX: (int)newX AVAILABLE_10_12; // expected-note{{marked partial here}}
@end
void test_property(void) {
  int y = InterWithProp.x; // expected-warning{{'InterWithProp' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  InterWithProp.x = y; // expected-warning{{'InterWithProp' is only available on macOS 10.12 or newer}} expected-note{{@available}} expected-warning{{'setX:' is only available on macOS 10.12 or newer}} expected-note{{@available}}
}

__attribute__((objc_root_class))
@interface Subscriptable
- (id)objectAtIndexedSubscript:(int)sub AVAILABLE_10_12; // expected-note{{marked partial here}}
@end

void test_at(Subscriptable *x) {
  id y = x[42]; // expected-warning{{'objectAtIndexedSubscript:' is only available on macOS 10.12 or newer}} expected-note{{@available}}
}

void uncheckAtAvailable() {
  if (@available(macOS 10.12, *) || 0) // expected-warning {{@available does not guard availability here; use if (@available) instead}}
    func_10_12(); // expected-warning {{'func_10_12' is only available on macOS 10.12 or newer}}
  // expected-note@-1 {{enclose 'func_10_12' in an @available check to silence this warning}}
}

void justAtAvailable() {
  int availability = @available(macOS 10.12, *); // expected-warning {{@available does not guard availability here; use if (@available) instead}}
}

#ifdef OBJCPP

int f(char) AVAILABLE_10_12;
int f(int);

template <class T> int use_f() {
  // FIXME: We should warn here!
  return f(T());
}

int a = use_f<int>();
int b = use_f<char>();

template <class> int use_at_available() {
  if (@available(macos 10.12, *))
    return func_10_12();
  else
    return func_10_12(); // expected-warning {{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{enclose}}
}

int instantiate_template() {
  if (@available(macos 10.12, *)) {
    use_at_available<char>();
  } else {
    use_at_available<float>();
  }
}

template <class>
int with_availability_attr() AVAILABLE_10_11 { // expected-note 2 {{marked partial here}}
  return 0;
}

int instantiate_with_availability_attr() {
  if (@available(macos 10.12, *))
    with_availability_attr<char>();
  else
    with_availability_attr<int>(); // expected-warning {{'with_availability_attr<int>' is only available on macOS 10.11 or newer}} expected-note {{enclose}}
}

int instantiate_availability() {
  if (@available(macOS 10.12, *))
    with_availability_attr<int_10_12>();
  else
    with_availability_attr<int_10_12>(); // expected-warning{{'with_availability_attr<int>' is only available on macOS 10.11 or newer}} expected-warning{{'int_10_12' is only available on macOS 10.12 or newer}} expected-note 2 {{enclose}}
}

auto topLevelLambda = [] () {
  func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  if (@available(macos 10.12, *))
    func_10_12();
};

void functionInFunction() {
  func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  struct DontWarnTwice {
    void f() {
      func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
    }
  };
  void([] () {
    func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  });
  (void)(^ {
    func_10_12(); // expected-warning{{'func_10_12' is only available on macOS 10.12 or newer}} expected-note{{@available}}
  });
}

#endif

struct InStruct { // expected-note{{annotate 'InStruct' with an availability attribute to silence}}
  new_int mem; // expected-warning{{'new_int' is partial}}

  struct { new_int mem; } anon; // expected-warning{{'new_int' is partial}} expected-note{{annotate anonymous struct with an availability attribute}}
};

#ifdef OBJCPP
static constexpr int AVAILABLE_10_12 SomeConstexprValue = 2; // expected-note{{marked partial here}}
typedef enum { // expected-note{{annotate anonymous enum with an availability attribute}}
  SomeValue = SomeConstexprValue // expected-warning{{'SomeConstexprValue' is partial}} 
} SomeEnum;
#endif

@interface InInterface
-(new_int)meth; // expected-warning{{'new_int' is partial}} expected-note{{annotate 'meth' with an availability attribute}}
@end

@interface Proper // expected-note{{annotate 'Proper' with an availability attribute}}
@property (class) new_int x; // expected-warning{{'new_int' is partial}}
@end

void with_local_struct() {
  struct local { // expected-note{{annotate 'local' with an availability attribute}}
    new_int x; // expected-warning{{'new_int' is partial}}
  };
}

// rdar://33156429:
// Avoid the warning on protocol requirements.

AVAILABLE_10_12
@protocol NewProtocol // expected-note {{'NewProtocol' has been explicitly marked partial here}}
@end

@protocol ProtocolWithNewProtocolRequirement <NewProtocol> // expected-note {{annotate 'ProtocolWithNewProtocolRequirement' with an availability attribute to silence}}

@property(copy) id<NewProtocol> prop; // expected-warning {{'NewProtocol' is partial: introduced in macOS 10.12}}

@end

@interface BaseClass
@end

@interface ClassWithNewProtocolRequirement : BaseClass <NewProtocol>

@end

@interface BaseClass (CategoryWithNewProtocolRequirement) <NewProtocol>

@end
