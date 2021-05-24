using FileIO, DataFrames, NRRD, Makie, CSV, Meshing, MeshIO, GeometryBasics, Colors, AxisArrays


const image_file = "JFRCtempate2010.mask130819_Original.nrrd"
const region_labels = "VFB domain list.csv"
const mesh_directory = "RegionMeshes"
global region_df = DataFrame(CSV.File(region_labels))


function choose_region(image, region::String)
	choose_region(image,region_number(region))
end
function choose_region(image, region; algo=MarchingCubes)
	region_image = falses(size(image))
	for r in region
		region_image .|= image .== r
	end

	mc = GeometryBasics.Mesh(region_image, algo(iso=1))
end



function region_number(r_number)
	region_df[r_number .== region_df.Name,:]."Stack id"
end

function region_name(r_name)
	region_df[r_name .== region_df."Stack id",:].Name[]
end

function region_id(r_number::Int)
	region_df[r_number .== region_df."Stack id",:]."JFRCtempate2010.mask130819"[]
end
function region_id(r_name::String)
	region_df[r_name .== region_df."Name",:]."JFRCtempate2010.mask130819"[]
end



function resize_mesh(mc, dimensions)

	new_coordinates = similar(coordinates(mc))
	for (i, vertex) in enumerate(coordinates(mc))
		new_coordinates[i] = vertex .* dimensions
	end

	return GeometryBasics.Mesh(new_coordinates, faces(mc))
end


function plot_brain(file::String)

	image_dims = maximum.(AxisArrays.axes(file))

	for region in region_df."Stack id"
		print("\rMeshing Region:", region)
		roi_mesh = choose_region(file, region)
		Makie.mesh!(resize_mesh(roi_mesh, image_dims), color=RGBA(1,1,1,.2))
	end
end
function plot_brain(mesh_dict; color=RGBA(1,1,1,.2))

	scene = Scene(show_axis=false)
	plot_brain!(scene, mesh_dict, color=color)
	return scene
end
function plot_brain!(scene, mesh_dict; color=RGBA(1,1,1,.2))

	for region in keys(mesh_dict)
		plot_region!(scene, mesh_dict, region, color=color)
	end
	return scene
end

function plot_region!(scene, mesh_dict, region::String; color=RGBA(1,1,1,.2))

	Makie.mesh!(scene, mesh_dict[region], color=color, transparency=true)
	return scene
end

function plot_regions!(scene, mesh_dict, regions::Vector{String}; color=RGBA(1,1,1,.2))
	for region in regions
		scene = plot_region!(scene, mesh_dict, region, color=color)
	end
	return scene
end

function save_meshes(nrrd_file)
	
	image_dims = maximum.(AxisArrays.axes(file))

	for region in region_df."Stack id"
		print("\rMeshing Region:", region)
		roi_mesh = choose_region(file, region)
		resized_mesh = resize_mesh(roi_mesh, image_dims)
		save(mesh_directory * "/" * region_id(region) * ".ply", resized_mesh)
	end	
end

function load_meshes()

	mesh_names = readdir(mesh_directory)

	# read the first mesh to get the type [There's something in the waters that means you can't explicitly name the GeometryBasics type]
	mc = load(mesh_directory * "/" * mesh_names[1])
	meshes = Dict{String, typeof(mc)}()
	sizehint!(meshes, length(mesh_names))
	meshes[mesh_names[1]] = mc

	for fname in mesh_names[2:end]
		print("\rLoading Region: ", fname[1:end-4])
		meshes[fname[1:end-4]] = load(mesh_directory * "/" * fname)
	end
	return meshes
end