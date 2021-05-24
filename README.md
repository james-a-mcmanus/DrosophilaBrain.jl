DrosophilaBrain.jl
Render the fruit fly brain within Makie.jl.
## Quickstart
```
# Load the meshes for each brain region
meshes = load_meshes()

# plot the whole brain
scene = plot_brain(meshes, color=RGBA(1,1,1,.2))

# plot a specific brain region
scene = Scene()
plot_region!(meshes, "LO_R", color=RGBA(1,0,0,.5))

# Highlight a brain-region(s)
scene = plot_brain(meshes, color=RGBA(1,1,1,.2))
plot_regions!(s, meshes, ["LO_R","LO_L"], color=RGBA(.1,1,.1,.2))
```