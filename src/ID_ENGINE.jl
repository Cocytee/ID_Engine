using Statistics
using FileIO

mutable struct ObjectParam
	Coord::Array{Int,1}
	Layer::AbstractString
	Img_map::Array{Float64,3}
	Img_ID::Array{Float64,3}
	Source::Bool
	DispPrio::Int
	function ObjectParam(A::Array{Int,1},B::AbstractString,C::Array{Float64,3},D::Array{Float64,3},E::Bool,F::Int)
		if (size(C)[1:2] != size(D)[1:2])
			error(":Img_map: need to have the same size as :Img_ID:")
		end
		new(A,B,C,D,E,F)
	end
end

mutable struct LightParam
	Coord::Array{Int,1}
	Layer::AbstractString
	Intensity::Float64
	GlowAmount::Float64
	Color::Array{Float64,1}
	function LightParam(A::Array{Int,1},B::AbstractString,C::Float64,D::Float64,E::Array{Float64,1})
		if (C<0)
			error("Need :Intensity: cannot be inferior to 0.0")
		end
		if (D<0)
			error("Need :GlowAmount: cannot be inferior to 0.0")
		end
		if (E[1]<0||E[1]>1||E[2]<0||E[2]>1||E[3]<0||E[3]>1)
			error("Need :Color: value between 1.0 and 0.0")
		end
		new(A,B,C,D,E)
	end
end

mutable struct LayerParam
	LayerDist::Float64
	function LayerParam(A::Float64)
		new(A)
	end
end

mutable struct SceneLights
	Light::Dict{AbstractString,LightParam}
	Object::Dict{AbstractString,ObjectParam}
	Layer::Dict{AbstractString,LayerParam}
	function SceneLights()
		new(Dict(),Dict(),Dict("central"=>LayerParam(0.0)))
	end
end

#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function askSceneLights(SL::SceneLights)
	printstyled("\nLights :\n",color=:green)
	for (k,i) in SL.Light
		println("\t['",k,"'] : @",i.Coord,"/layer-> ",i.Layer,".\n\t|> Color : [",i.Color[1],";",i.Color[2],";",i.Color[3],"] ",i.Intensity*100,"%"," |> Amount of glow :",i.GlowAmount*100,"%")
	end
	printstyled("\nObjects :\n",color=:green)
	for (k,i) in SL.Object
		println("\t['",k,"'] : @",i.Coord,"/layer-> ",i.Layer,".\n\t|> Light Source ? : ",i.Source, " |> Display Pritority : ",i.DispPrio)
	end
	printstyled("\nLayers :\n",color=:green)
	for (k,i) in SL.Layer
		println("\tLayer[",k,"] @",i.LayerDist,"m from central layer.")
	end
	println()
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
"""
	\tLoadImgFloat(fileIMG::String)\n
	\t\tReturn (Array{Float64,2},Array{Float64,2},Array{Float64,2})
Load an image , extract the R G B matrices and convert them to Float64 (btw 0.0 and 1.0).\n
Return the (Float) R G B matrices\n
"""
function ImgtoFloat(fileIMG::String)
	img = load(fileIMG)
	(h,l) = size(img)
	r = Array{Float64,3}(undef,h,l,4)
	@inbounds for i = 1:h , j = 1:l
		r[i,j,1] = img[i,j].r
		r[i,j,2] = img[i,j].g
		r[i,j,3] = img[i,j].b
		r[i,j,4] = img[i,j].alpha
	end
	return r
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function IDtoNormal(fileNORM::String)
	norm = load(fileNORM)
	(h,l) = size(norm)
	r = Array{Float64,3}(undef,h,l,3)
	@inbounds for i = 1:h , j = 1:l
		if norm[i,j].alpha == 0.0
			r[i,j,1] = false
			r[i,j,2] = false
			r[i,j,3] = false
		else
		(r[i,j,1],r[i,j,2],r[i,j,3]) = norm_angle(Float64(norm[i,j].r),Float64(norm[i,j].g),Float64(norm[i,j].b))
		end
	end
	return r
end

#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function spwnLight!(List::SceneLights,Name::AbstractString,Coord::Array{Int,1},Layer::AbstractString,Intensity::Float64,Glow::Float64,Color::Array{Float64,1})
	temp = LightParam(Coord,Layer,Intensity,Glow,Color)
	if length(List.Layer) > 0
		if length(filter(x -> (x == Layer), keys(List.Layer))) == 0
			printstyled("\n\t * Layer -",temp.Layer,"- doesn't exists !"," Light *",Name,"* ,not created\n",color=:red)
			return false;
		else
			List.Light[Name] = temp
			return true;
		end
	else
		printstyled("\n\t * Layers not initialized !\n",color=:red)
		return false;
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function spwnObject!(List::SceneLights,Name::AbstractString,Coord::Array{Int,1},Layer::AbstractString,Img::Array{Float64,3},ID::Array{Float64,3};Source=false,DispPrio=0)
	temp = ObjectParam(Coord,Layer,Img,ID,Source,DispPrio)
	if length(List.Layer) > 0
		if length(filter(x -> (x == Layer), keys(List.Layer))) == 0
			printstyled("\n\t * Layer -",temp.Layer,"- doesn't exists !"," Object *",Name,"* ,not created\n",color=:red)
			return false;
		else
			List.Object[Name] = temp
			return true;
		end
	else
		printstyled("\n\t * Layers not initialized !\n",color=:red)
		return false;
	end
end
function spwnObject!(List::SceneLights,Name::AbstractString,Coord::Array{Int,1},Layer::AbstractString,fImg::AbstractString,fID::AbstractString;Source=false,DispPrio=0)
	tImg = ImgtoFloat(fImg)
	tID = IDtoNormal(fID)
	temp = ObjectParam(Coord,Layer,tImg,tID,Source,DispPrio)
	if length(List.Layer) > 0
		if length(filter(x -> (x == Layer), keys(List.Layer))) == 0
			printstyled("\n\t * Layer -",temp.Layer,"- doesn't exists !"," Object *",Name,"* ,not created\n",color=:red)
			return false;
		else
			List.Object[Name] = temp
			return true;
		end
	else
		printstyled("\n\t * Layers not initialized !\n",color=:red)
		return false;
	end
end
function spwnObject!(List::SceneLights,Name::AbstractString,Coord::Array{Int,1},Layer::AbstractString,Img::Array{Float64,3};DispPrio=0)
	tID = Array{Float64,3}(undef,1,1,1)
	temp = ObjectParam(Coord,Layer,Img,tID,true,DispPrio)
	if length(List.Layer) > 0
		if length(filter(x -> (x == Layer), keys(List.Layer))) == 0
			printstyled("\n\t * Layer -",temp.Layer,"- doesn't exists !"," Object *",Name,"* ,not created\n",color=:red)
			return false;
		else
			List.Object[Name] = temp
			return true;
		end
	else
		printstyled("\n\t * Layers not initialized !\n",color=:red)
		return false;
	end
end
function spwnObject!(List::SceneLights,Name::AbstractString,Coord::Array{Int,1},Layer::AbstractString,fImg::AbstractString;DispPrio=0)
	tImg = ImgtoFloat(fImg)
	tID = Array{Float64,3}(undef,1,1,1)
	temp = ObjectParam(Coord,Layer,tImg,tID,true,DispPrio)
	if length(List.Layer) > 0
		if length(filter(x -> (x == Layer), keys(List.Layer))) == 0
			printstyled("\n\t * Layer -",temp.Layer,"- doesn't exists !"," Object *",Name,"* ,not created\n",color=:red)
			return false;
		else
			List.Object[Name] = temp
			return true;
		end
	else
		printstyled("\n\t * Layers not initialized !\n",color=:red)
		return false;
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function spwnLayer!(List::SceneLights,Layer::AbstractString,Dist::Float64)
	temp = (Layer => LayerParam(Dist))
	if length(List.Layer) > 0
		if length(filter(x -> (x == Layer), keys(List.Layer))) > 0
			printstyled("\n\t * Layer ",temp.Layer," already exists !\n",color=:red)
			return false;
		else
			push!(List.Layer,temp)
			return true;
		end
	else
		push!(List.Layer,temp)
		return true;
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function killLight!(List::SceneLights,Name::AbstractString)
	if haskey(List.Light,Name)
		delete!(List.Light,Name)
		return true
	else
		printstyled("Light(s) *",Name,"* not found\n",color=:red)
		return false
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function killObject!(List::SceneLights,Name::AbstractString)
	if haskey(List.Object,Name)
		delete!(List.Object,Name)
		return true
	else
		printstyled("Object(s) *",Name,"* not found\n",color=:red)
		return false
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function killLayer!(List::SceneLights,Layer::Int)
	#Can't kill layer 0
	if Layer == "central"
		printstyled("Can't kill central layer \n",color=:red)
		return false
	else
		temp = filter(x -> (x != Layer), keys(List.Layer))
		if(length(temp) == length(List.Layer))
			printstyled("Can't kill a layer that doesn't exists !\n",color=:red)
			return false
		else
			List.Layer = temp
			return true
		end
	end

end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function tuneLight!(List::SceneLights,Name::AbstractString;
	Coord::Union{String,Array{Int,1}}="x",
	Layer::AbstractString="x",
	Intensity::Union{String,Float64}="x",
	GlowAmount::Union{String,Float64}="x",
	Color::Union{String,Array{Float64,1}}="x"
	)
	if haskey(List.Light,Name)
		if typeof(Coord) == Array{Int,1}
			List.Light[Name].Coord = Coord
		end 
		if Layer != "x"
			List.Light[Name].Layer = Layer
		end 
		if typeof(Intensity) == Float64
			List.Light[Name].Intensity = Intensity
		end 
		if typeof(Intensity) == Float64
			List.Light[Name].GlowAmount = GlowAmount
		end 
		if typeof(Color) == Array{Float64,1}
		    List.Light[Name].Color = Color
		end    
		return true
	else
		printstyled("Light(s) *",Name,"* not found\n",color=:red)
		return false
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function tuneLayer!(List::SceneLights,Layer::AbstractString;
	LayerDist::Union{String,Float64}="x"
	)

	if length(filter(x -> (x == Layer), keys(List.Layer))) != 0
		if typeof(LayerDist) == Float64
			List.Layer[Layer].LayerDist = LayerDist
		end  
		return true
	else
		printstyled("Layer *",Num,"* not found\n",color=:red)
		return false
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function tuneObject!(List::SceneLights,Name::AbstractString;
	Coord::Union{String,Array{Int,1}}="x",
	Layer::AbstractString="x",
	Img_map::Union{String,Array{Float64,3}}="x",
	Img_ID::Union{String,Array{Float64,3}}="x",
	Source::Union{String,Bool}="x",
	DispPrio::Union{String,Int}="x"
	)
	if haskey(List.Object,Name)
		if typeof(Coord) == Array{Int,1}
			List.Object[Name].Coord = Coord
		end 
		if Layer != "x"
			List.Object[Name].Layer = Layer
		end 
		if typeof(Img_map) == Array{Float64,3}
			List.Object[Name].Img_map = Img_map
		end 
		if typeof(Img_ID) == Array{Float64,3}
		    List.Object[Name].Img_ID = Img_ID
		end  
		if typeof(Source) == Bool
		    List.Object[Name].Source = Source
		end   
		if typeof(DispPrio) == Int
		    List.Object[Name].DispPrio = DispPrio
		end     
		return true
	else
		printstyled("Object(s) *",Name,"* not found\n",color=:red)
		return false
	end
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function norm_angle(r::Float64,g::Float64,b::Float64) 
	tr = (r != 0 && r < 1.0)-(r==1.0)
	tg = (g != 0 && g < 1.0)-(g==1.0)
	tb = (b==1.0)-(b != 0 && b < 1.0)
	return tr, tg, tb
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Intensity -> Distance in pixel for the Lenticular Light Limit (decrease of 60%) | Glow -> Gaussian form factor
light_distance(intensity,distance,glow) = exp(-(distance/intensity)^(1+glow))
rd(x,y,z) = sqrt(x^2 + y^2 + z^2)

tetha(x,y) =atan(y,x)
phi(x,y,z) = z/sqrt(x^2+y^2+z^2)

# TROVER LA BONNE EQUATION
n_light(x,y,z,idx,idy,idz) = abs(tetha(x,y) - tetha(idx,idy)) * ((idx+idy) != 0)
#n_light(xn,yn,zn,idx,idy,idz) = (3 - (abs(xn+idx)+abs(yn+idy)+abs(zn+idz))) / 3
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function Ray_ID(List::SceneLights,Name::AbstractString)
	#if object is Source, no shading needed
	if List.Object[Name].Source
		return List.Object[Name].Img_map
	end

	(h,l) = size(List.Object[Name].Img_map)

	#black object w/ same opacity features
	current  = copy(List.Object[Name].Img_map)
	current[:,:,1:3] .= 0.0

	debug1 = zeros(size(current)[1],size(current)[2])

	#for each light
	for n in keys(sort(List.Light))
		z = List.Layer[List.Object[Name].Layer].LayerDist - List.Layer[List.Light[n].Layer].LayerDist
		
		#for each pixels
		for i=1:h , j=1:l
			#ray vector
			x = (List.Object[Name].Coord[1]-List.Light[n].Coord[1])+(j-1)
			y = (List.Object[Name].Coord[2]-List.Light[n].Coord[2])+(i-1)
			#normlization
			(xn,yn,zn) = normalize(float(x),float(y),float(z))
			#distance between light and pixel
			r = rd(x,y,z)

			#for each color
			if (List.Object[Name].Img_map[i,j,4] != 0) 
				#light vs normals
				normal_weight = n_light(xn,yn,zn,List.Object[Name].Img_ID[i,j,1],List.Object[Name].Img_ID[i,j,2],List.Object[Name].Img_ID[i,j,3])

				debug1[i,j] = normal_weight

				if ( (normal_weight > (pi/2)) && (normal_weight < (pi+(pi/2))) )				
					#light vs distance
					li = ((light_distance(List.Light[n].Intensity,r,List.Light[n].GlowAmount).*List.Light[n].Color) .* List.Object[Name].Img_map[i,j,1:3])
					#applying normals
					li = li .* ((pi - abs(normal_weight - pi))/pi)
					#adding light to pixel
					current[i,j,1:3] = current[i,j,1:3] .+ li
				end
			end
		end
	end
	return current,debug1
end

function Ray_ID(List::SceneLights)
	
end
#::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
function Render_ID()
	
end
