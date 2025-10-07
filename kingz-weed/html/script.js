let currentPlantId = null;
let harvestProgress = 0;
let totalLeaves = 0;
let harvestedLeaves = 0;

$(document).ready(function() {
    // Hide containers initially
    $("#plant-info").hide();
    $("#harvesting").hide();
    
    // Close plant info
    $("#close-plant-info").click(function() {
        $("#plant-info").fadeOut();
        $.post('https://kingz-weed/closeMenu', JSON.stringify({}));
    });
    
    // Cancel harvest
    $("#cancel-harvest").click(function() {
        $("#harvesting").fadeOut();
        $.post('https://kingz-weed/cancelHarvest', JSON.stringify({}));
    });
    
    // Plant action buttons
    $("#water-plant").click(function() {
        $.post('https://kingz-weed/plantAction', JSON.stringify({
            plantId: currentPlantId,
            action: "water"
        }));
        $("#plant-info").fadeOut();
    });
    
    $("#fertilize-plant").click(function() {
        $.post('https://kingz-weed/plantAction', JSON.stringify({
            plantId: currentPlantId,
            action: "fertilize"
        }));
        $("#plant-info").fadeOut();
    });
    
    $("#pesticide-plant").click(function() {
        $.post('https://kingz-weed/plantAction', JSON.stringify({
            plantId: currentPlantId,
            action: "pesticide"
        }));
        $("#plant-info").fadeOut();
    });
    
    $("#medicine-plant").click(function() {
        $.post('https://kingz-weed/plantAction', JSON.stringify({
            plantId: currentPlantId,
            action: "medicine"
        }));
        $("#plant-info").fadeOut();
    });
    
    $("#harvest-plant").click(function() {
        $.post('https://kingz-weed/plantAction', JSON.stringify({
            plantId: currentPlantId,
            action: "harvest"
        }));
        $("#plant-info").fadeOut();
    });
    
    $("#destroy-plant").click(function() {
        $.post('https://kingz-weed/plantAction', JSON.stringify({
            plantId: currentPlantId,
            action: "destroy"
        }));
        $("#plant-info").fadeOut();
    });
    
    // Listen for messages from the game
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        if (data.type === "showPlantInfo") {
            showPlantInfo(data.plantInfo);
        } else if (data.type === "startHarvesting") {
            startHarvesting(data.plantInfo);
        }
    });
});

function showPlantInfo(plantInfo) {
    currentPlantId = plantInfo.id;
    
    // Update plant info
    $("#plant-name").text(plantInfo.name + (plantInfo.isHybrid ? " (Hybrid)" : ""));
    $("#plant-stage").text(plantInfo.stage + "/" + plantInfo.maxStage);
    $("#plant-time").text(plantInfo.timeLeft > 0 ? plantInfo.timeLeft + " minutes" : "Ready to harvest");
    
    // Update progress bars
    $("#water-progress").css("width", plantInfo.water + "%");
    $("#water-value").text(plantInfo.water + "%");
    
    $("#fertilizer-progress").css("width", plantInfo.fertilizer + "%");
    $("#fertilizer-value").text(plantInfo.fertilizer + "%");
    
    $("#health-progress").css("width", plantInfo.health + "%");
    $("#health-value").text(plantInfo.health + "%");
    
    $("#quality-progress").css("width", plantInfo.quality + "%");
    $("#quality-value").text(plantInfo.qualityLevel + " (" + plantInfo.quality + "%)");
    
    // Update status items
    $("#bugs-status span").text("Bugs: " + (plantInfo.hasBugs ? "Infested" : "None"));
    $("#bugs-status i").css("color", plantInfo.hasBugs ? "#e74c3c" : "#27ae60");
    
    $("#disease-status span").text("Disease: " + (plantInfo.hasDisease ? "Infected" : "None"));
    $("#disease-status i").css("color", plantInfo.hasDisease ? "#e74c3c" : "#27ae60");
    
    $("#lamp-status span").text("Heat Lamp: " + (plantInfo.isUnderHeatLamp ? "Active" : "Off"));
    $("#lamp-status i").css("color", plantInfo.isUnderHeatLamp ? "#f39c12" : "#7f8c8d");
    
    $("#hydro-status span").text("Hydroponic: " + (plantInfo.isHydroponic ? "Yes" : "No"));
    $("#hydro-status i").css("color", plantInfo.isHydroponic ? "#3498db" : "#7f8c8d");
    
    // Update content values
    $("#thc-value").text(plantInfo.thcContent + "%");
    $("#cbd-value").text(plantInfo.cbdContent + "%");
    
    // Enable/disable harvest button
    $("#harvest-plant").prop("disabled", !plantInfo.readyToHarvest);
    
    // Show the container
    $("#plant-info").fadeIn();
}

function startHarvesting(plantInfo) {
    currentPlantId = plantInfo.id;
    harvestProgress = 0;
    totalLeaves = plantInfo.leaves;
    harvestedLeaves = 0;
    
    // Update progress bar
    $("#harvest-progress-bar").css("width", "0%");
    $("#harvest-progress-value").text("0%");
    
    // Create leaves
    $("#harvest-leaves").empty();
    for (let i = 0; i < totalLeaves; i++) {
        const leaf = $("<div>").addClass("leaf").attr("data-index", i);
        leaf.click(function() {
            if (!$(this).hasClass("harvested")) {
                harvestLeaf($(this));
            }
        });
        $("#harvest-leaves").append(leaf);
    }
    
    // Show the container
    $("#harvesting").fadeIn();
}

function harvestLeaf(leafElement) {
    leafElement.addClass("harvested");
    harvestedLeaves++;
    
    // Update progress
    harvestProgress = (harvestedLeaves / totalLeaves) * 100;
    $("#harvest-progress-bar").css("width", harvestProgress + "%");
    $("#harvest-progress-value").text(Math.floor(harvestProgress) + "%");
    
    // Check if harvesting is complete
    if (harvestedLeaves >= totalLeaves) {
        // Send completion to game
        setTimeout(function() {
            $.post('https://kingz-weed/harvestProgress', JSON.stringify({
                plantId: currentPlantId,
                progress: 100
            }));
        }, 500);
    }
}
