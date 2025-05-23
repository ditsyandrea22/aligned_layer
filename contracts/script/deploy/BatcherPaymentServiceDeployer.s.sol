pragma solidity ^0.8.12;

import {BatcherPaymentService} from "../../src/core/BatcherPaymentService.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAlignedLayerServiceManager} from "../../src/core/IAlignedLayerServiceManager.sol";

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";

contract BatcherPaymentServiceDeployer is Script {
    function run(string memory batcherConfigPath, string memory outputPath) external returns (address, address) {
        // READ JSON CONFIG DATA
        string memory config_data = vm.readFile(batcherConfigPath);

        address batcherWallet = stdJson.readAddress(config_data, ".address.batcherWallet");

        address alignedLayerServiceManager = stdJson.readAddress(config_data, ".address.alignedLayerServiceManager");

        address batcherPaymentServiceOwner = stdJson.readAddress(config_data, ".permissions.owner");

        vm.startBroadcast();

        BatcherPaymentService batcherPaymentService = new BatcherPaymentService();

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(batcherPaymentService),
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                IAlignedLayerServiceManager(alignedLayerServiceManager),
                batcherPaymentServiceOwner,
                batcherWallet
            )
        );

        vm.stopBroadcast();

        string memory addresses = "addresses";
        vm.serializeAddress(addresses, "batcherPaymentService", address(proxy));
        string memory addressesStr =
            vm.serializeAddress(addresses, "batcherPaymentServiceImplementation", address(batcherPaymentService));

        string memory parentObject = "parent";
        string memory finalJson = vm.serializeString(parentObject, "addresses", addressesStr);
        vm.writeJson(finalJson, outputPath);

        return (address(proxy), address(batcherPaymentService));
    }
}
