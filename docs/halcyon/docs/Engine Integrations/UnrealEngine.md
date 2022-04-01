# Unreal Engine Runtime

## C++ Plugin Level API

- primary API implemented as an unreal engine game subsystem.
- based on "providing rich and sane defaults" 
- Available as a ticking subsystem (default) or as a non-ticking subsystem.
- The Event system is available if the subsystem is ticking.
- Automatic memory management at this point.
- Provides high level C++ api for use with blueprints

### Capabilities

- Create Story Registry(s)
- Parse and load story registries
- Data assets for .halc projects
- Importers for .halc files

## Blueprint Game Level API
- A collection of functions, macros, and blueprint interfaces.
- Most of the usage examples in the gameplay implementations.
- Section are implemented at this layer.