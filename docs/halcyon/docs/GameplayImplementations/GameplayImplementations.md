# Gameplay Implementations

In this section I will overlay various implementation types of implementations and frameworks for use in halcyon.
This is partially a set of thought exercises intended for assisting with guiding the design of the halcyon runtime.

## Basic Usage: Simple Interactors

Here's some light pseudocoding. Most of these will be written in the standard C interface.
A native unreal engine style interface will be generated later.

```{c}
struct chars_t {
    const char* s;
    size_t len;
};

struct new_interactor_params
{
    chars_t labelStartName;
};

MakeIntParams_t p = Halc_newParams();
p.startLabel = "";

InteractorHandle_t = Ecs_createInteractor();
```