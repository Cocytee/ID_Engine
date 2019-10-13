#import Pkg
#Pkg.add("Gadfly")

include("../src/ID_ENGINE.jl")

using PyPlot
using DelimitedFiles

printstyled("STARTING THE TEST...\n",bold=true,color=:light_cyan)

printstyled("Loading the pictures... ",bold=true,color=:bold)
m = ImgtoFloat("test.png")
mi = ImgtoFloat("test_ID.png")
printstyled("DONE\n",bold=false,color=:yellow)

printstyled("Creating Lighting Environnement... ",bold=true,color=:bold)
sl = SceneLights()
printstyled("DONE\n",bold=false,color=:yellow)

printstyled("Setting the layers... ",bold=true,color=:bold)
spwnLayer!(sl,"land",5.0)
spwnLayer!(sl,"rocks",-0.5)
printstyled("DONE\n",bold=false,color=:yellow)

printstyled("Spawning the lights... ",bold=true,color=:bold)
spwnLight!(sl,"jose",[2,2],"central",20.0,0.0,[1.0,1.0,0.0])
spwnLight!(sl,"bob",[16,16],"land",10.0,0.0,[1.0,0.0,1.0])
printstyled("DONE\n",bold=false,color=:yellow)

printstyled("Spawning the objects... ",bold=true,color=:bold)
spwnObject!(sl,"carreau",[4,4],"central","test.png","test_ID.png")
printstyled("DONE\n",bold=false,color=:yellow)

askSceneLights(sl)

printstyled("Processing... ",bold=true,color=:bold)
pp = Ray_ID(sl,"carreau")
printstyled("DONE\n",bold=false,color=:yellow)

printstyled("Displaying the pictures... ",bold=true,color=:bold)
subplot(1,3,1)
imshow(m)
subplot(1,3,2)
imshow(mi)
subplot(1,3,3)
imshow(pp)
printstyled("DONE\n",bold=false,color=:yellow)

printstyled("ENDING THE TEST...\n",bold=true,color=:light_magenta)

#How to display
#bring light