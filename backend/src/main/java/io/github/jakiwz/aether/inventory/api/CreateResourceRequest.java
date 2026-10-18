package io.github.jakiwz.aether.inventory.api;

import io.github.jakiwz.aether.inventory.domain.NewResource;
import io.github.jakiwz.aether.inventory.domain.ResourceCategory;
import io.github.jakiwz.aether.shared.validation.PlainText;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.jspecify.annotations.Nullable;

@Schema(name = "CreateResource", description = "Adds a consumable resource to the catalogue (ORI-401).")
public record CreateResourceRequest(
        @Schema(description = "Unique code; stored upper case", example = "CO2_SCRUBBER")
        @NotBlank @Pattern(regexp = "^[A-Za-z0-9][A-Za-z0-9_-]{1,49}$",
                message = "must be 2-50 letters, digits, dashes or underscores") String code,
        @Schema(example = "CO2 scrubber cartridge") @NotBlank @Size(max = 150) @PlainText String name,
        @Schema(description = "Resource category") @NotNull ResourceCategory category,
        @Schema(description = "Code of a unit of measure; mandatory, never inferred from the name", example = "PCS")
        @NotBlank @Size(max = 20) @PlainText String unitCode,
        @Schema(description = "True when running out endangers the crew", example = "true") @NotNull Boolean critical,
        @Schema(description = "Days a lot stays usable, when the resource expires", example = "365", nullable = true)
        @Min(1) @Max(36_500) @Nullable Integer shelfLifeDays) {

    NewResource toCommand() {
        return new NewResource(code, name, category, unitCode, critical, shelfLifeDays);
    }
}
