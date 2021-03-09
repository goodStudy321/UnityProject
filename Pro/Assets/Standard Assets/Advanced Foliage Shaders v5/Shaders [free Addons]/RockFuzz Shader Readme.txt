Rock Fuzz Shader


This is a simple shader, which supports instancing and fuzz lighting or diffuse scattering in order to enhance the look of moss.

Shader Inputs

Albedo (RGB) Smoothness (A): As the texture name says: This slot expects an albedo texture which contains smoothness in the alpha channel.
Normal: Just a regular Bump Map.
Specular Reflectivity: Lets you define the specular color. Usrually you just want to use the standard value wich is RGB = 51, 51, 51.
Fuzz Mask (G): Texture which contains a mask for all the parts which shall receive fuzz lighting. This mask also defines the strength, so you may use grayscale values. The mask is sampled from the green texture channel.
Scatter Power: Lets you sharpen the diffuse light scattering towards grazing angles.
Scatter Bias: Lets you raise the diffuse light scattering by adding a constant.

