# mit-app-inventor-utils

Utilities to be used with MIT App Inventor

# Create a PDF document with the images

To run the scripts you need to have imagemagick installed. 

In the following documentation the default values of some parameters are used. Execute the scripts with the option `-h` for more help.

In MIT App Inventor, in the blocks view
- Expand Blocks
- Sort Blocks by Category (recommended)
- Arrange Blocks Vertically
- Download Blocks as Image and save it locally as `data/block.png`

The transformation has two phases:
- Split the big image in blocks
- Combine all the images in a PDF

You can run both steps together with

    ./splitBlock -SC

## Split the image

This process takes a while (be patient)

    ./splitBlock -Ss

or if you want to see the traces

    ./splitBlock -S

Once the process finishes, the folder `data/out` contains all the smaller images.

The split process is executed once. It can be done several times until all the individual images are obtained but:
- This can take a lot of time (depending on your code)
- We have to combine the images again

But in case you want to add more "loops" (at this moment this is not a parameter) yo can edit `split.sh` and look for:

    # Split Once
    if [ $step -eq 1 ]
    then
      cp $workDir/* $dstDir
      break
    fi

and change the `1` but the number steps you want.

## Create the PDF

Just execute 

    ./splitBlock -C

## Examples

- [Initial Image](docs/blocks.png)
- Images created
  - [blocks-0.png](docs/out/new_blocks-0.png)
  - [blocks-1.png](docs/out/new_blocks-1.png)
  - [blocks-2.png](docs/out/new_blocks-2.png)
  - [blocks-3.png](docs/out/new_blocks-3.png)
  - [blocks-4.png](docs/out/new_blocks-4.png)
  - [blocks-5.png](docs/out/new_blocks-5.png)
  - [blocks-6.png](docs/out/new_blocks-6.png)
  - [blocks-7.png](docs/out/new_blocks-7.png)
- [PDF created](docs/out.pdf)
