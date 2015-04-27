#include "test/test.hpp"

#include <catch.hpp>

#include <cthun-agent/modules/inventory.hpp>
#include <cthun-agent/errors.hpp>

#include <cthun-client/data_container/data_container.hpp>
#include <cthun-client/protocol/chunks.hpp>       // ParsedChunks

#include <string>
#include <vector>

extern std::string ROOT_PATH;

namespace CthunAgent {

static const std::string inventory_action { "inventory" };
static const std::string inventory_txt {
    "{  \"module\" : \"inventory\","
    "   \"action\" : \"inventory\","
    "   \"params\" : {}"
    "}"
};

static const std::vector<CthunClient::DataContainer> no_debug {};
static const CthunClient::ParsedChunks parsed_chunks {
                    CthunClient::DataContainer(),
                    CthunClient::DataContainer(inventory_txt),
                    no_debug };

TEST_CASE("Modules::Inventory::callAction", "[modules]") {
    Modules::Inventory inventory_module {};

    SECTION("the inventory module is correctly named") {
        REQUIRE(inventory_module.module_name == "inventory");
    }

    SECTION("the inventory module has the inventory action") {
        REQUIRE(inventory_module.actions.find(inventory_action)
                != inventory_module.actions.end());
    }

    SECTION("it can call the inventory action") {
        REQUIRE_NOTHROW(inventory_module.callAction(inventory_action,
                                                    parsed_chunks));
    }

    SECTION("it should execute the inventory action correctly") {
        auto result = inventory_module.callAction(inventory_action,
                                                  parsed_chunks);
        CHECK(result.toString().find("facts") != std::string::npos);
    }
}

}  // namespace CthunAgent