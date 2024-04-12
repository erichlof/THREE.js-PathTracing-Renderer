// Define card data
const cardsData = [
    { title: "Arctic Circle", imageUrl: "imgs/card-icons/1.png", link: "Arctic_Circle.html" },
    { title: "Bi-Directional Difficult Lighting", imageUrl: "imgs/card-icons/2.png", link: "Bi-Directional_Difficult_Lighting.html" },
    { title: "Bi-Directional Pathtracing", imageUrl: "imgs/card-icons/3.png", link: "Bi-Directional_PathTracing.html" },
    { title: "Billiard_Table", imageUrl: "imgs/card-icons/4.png", link: "Billiard_Table.html" },
    { title: "BVH Animated Model", imageUrl: "imgs/card-icons/5.png", link: "BVH_Animated_Model.html" },
    { title: "BVH_Model Instancing", imageUrl: "imgs/card-icons/6.png", link: "BVH_Model_Instancing.html" },
    { title: "BVH_Point Light Source", imageUrl: "imgs/card-icons/7.png", link: "BVH_Point_Light_Source.html" },
    { title: "BVH_Spot Light Source", imageUrl: "imgs/card-icons/8.png", link: "BVH_Spot_Light_Source.html" },
    { title: "BVH Terrain", imageUrl: "imgs/card-icons/9.png", link: "BVH_Terrain.html" },
    { title: "BVH Visualizer", imageUrl: "imgs/card-icons/10.png", link: "BVH_Visualizer.html" },
    { title: "Cheap Torus", imageUrl: "imgs/card-icons/11.png", link: "Cheap_Torus.html" },
    { title: "Classic Scene: Appel", imageUrl: "imgs/card-icons/12.png", link: "Classic_Scene_Appel_ShadingMachineRenderingsOfSolids.html" },
    { title: "Classic Scene: Kajiya The Rendering Equation", imageUrl: "imgs/card-icons/13.png", link: "Classic_Scene_Kajiya_TheRenderingEquation.html" },
    { title: "Classic Scene: Whitted The Compleat Angler", imageUrl: "imgs/card-icons/14.png", link: "Classic_Scene_Whitted_TheCompleatAngler.html" },
    { title: "Compare Bi-Directional Approach", imageUrl: "imgs/card-icons/15.png", link: "Compare_Bi-Directional_Approach.html" },
    { title: "Compare Uni-Directional Approach", imageUrl: "imgs/card-icons/16.png", link: "Compare_Uni-Directional_Approach.html" },
    { title: "Constructive Solid Geometry Viewer", imageUrl: "imgs/card-icons/17.png", link: "Constructive_Solid_Geometry_Viewer.html" },
    { title: "Convex Polyhedra", imageUrl: "imgs/card-icons/18.png", link: "Convex_Polyhedra.html" },
    { title: "Cornell Box", imageUrl: "imgs/card-icons/19.png", link: "Cornell_Box.html" },
    { title: "CSG Museum 1", imageUrl: "imgs/card-icons/20.png", link: "CSG_Museum_1.html" },
    { title: "CSG Museum 2", imageUrl: "imgs/card-icons/21.png", link: "CSG_Museum_2.html" },
    { title: "CSG Museum 3", imageUrl: "imgs/card-icons/22.png", link: "CSG_Museum_3.html" },
    { title: "CSG Museum 4", imageUrl: "imgs/card-icons/23.png", link: "CSG_Museum_4.html" },
    { title: "Fractal 3D", imageUrl: "imgs/card-icons/24.png", link: "Fractal3D.html" },
    { title: "Game Engine PathTracer", imageUrl: "imgs/card-icons/25.png", link: "GameEngine_PathTracer.html" },
    { title: "GLTF Model Viewer", imageUrl: "imgs/card-icons/26.png", link: "GLTF_Model_Viewer.html" },
    { title: "Grid Acceleration", imageUrl: "imgs/card-icons/27.png", link: "Grid_Acceleration.html" },
    { title: "HDRI Environment", imageUrl: "imgs/card-icons/28.png", link: "HDRI_Environment.html" },
    { title: "Invisible Date", imageUrl: "imgs/card-icons/29.png", link: "Invisible_Date.html" },
    { title: "Light Shafts", imageUrl: "imgs/card-icons/30.png", link: "Light_Shafts.html" },
    { title: "Material Roughness", imageUrl: "imgs/card-icons/31.png", link: "Material_Roughness.html" },
    { title: "MultiSamples Per Frame", imageUrl: "imgs/card-icons/32.png", link: "MultiSamples_Per_Frame.html" },
    { title: "MultiSPF Dynamic Scene", imageUrl: "imgs/card-icons/33.png", link: "MultiSPF_Dynamic_Scene.html" },
    { title: "Ocean And Sky Rendering", imageUrl: "imgs/card-icons/34.png", link: "Ocean_And_Sky_Rendering.html" },
    { title: "Planet Rendering", imageUrl: "imgs/card-icons/35.png", link: "Planet_Rendering.html" },
    { title: "Quadric_Geometry_Showcase", imageUrl: "imgs/card-icons/36.png", link: "Quadric_Geometry_Showcase.html" },
    { title: "Quadric Shapes Explorer", imageUrl: "imgs/card-icons/37.png", link: "Quadric_Shapes_Explorer.html" },
    { title: "Ray Warping", imageUrl: "imgs/card-icons/38.png", link: "Ray_Warping.html" },
    { title: "Sphereflake", imageUrl: "imgs/card-icons/39.png", link: "Sphereflake.html" },
    { title: "Switching Materials", imageUrl: "imgs/card-icons/40.png", link: "Switching_Materials.html" },
    { title: "Terrain Rendering", imageUrl: "imgs/card-icons/41.png", link: "Terrain_Rendering.html" },
    { title: "Transforming Quadric Geometry Showcase", imageUrl: "imgs/card-icons/42.png", link: "Transforming_Quadric_Geometry_Showcase.html" },
    { title: "Volumetric_Rendering", imageUrl: "imgs/card-icons/43.png", link: "Volumetric_Rendering.html" },
    { title: "Water Rendering", imageUrl: "imgs/card-icons/44.png", link: "Water_Rendering.html" },
    // Add more cards as needed
];

// Function to create cards
function createCard(title, imageUrl, link) {
    const card = document.createElement("div");
    card.classList.add("card");
    // card.classList.add("dark:bg-slate-500");
    card.classList.add("border-x-2");

    const img = document.createElement("img");
    img.src = imageUrl;
    img.alt = title;

    const heading = document.createElement("h3");
    heading.textContent = title;

    card.appendChild(img);
    card.appendChild(heading);

    // Add link functionality
    card.addEventListener("click", () => {
        window.location.href = link;
    });

    return card;
}

// Function to initialize the grid with cards
function initializeGrid() {
    const container = document.getElementById("card-container");
    cardsData.forEach(({ title, imageUrl, link }) => {
        const card = createCard(title, imageUrl, link);
        container.appendChild(card);
    });
}

// Initialize grid when the page loads
window.addEventListener("load", initializeGrid);
