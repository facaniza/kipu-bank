//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
/*
    @title KipuBank - un banco en blockchain
    @author Facundo Alejandro Caniza
*/
contract KipuBank {

    //@notice umbral para fijo para transaccion
    uint constant umbral = 10;
    //@notice limite global de deposito
    uint immutable bankCap;
    //@notice cantidad de depositos del contrato
    uint private depositos;
    //@notice cantidad de retiros del contrato
    uint private retiros;
    //@notice total de ether depositado en el contrato
    uint private totalContrato;

    //@notice estructura que almacena por titular el monto que posee en la boveda
    mapping (address titular => uint monto) private boveda;


    //@notice Evento para depositos realizado exitosamente
    event KipuBank_DepositoRealizado(address titular, uint monto);
    //@notice Evento para extracciones realizadas exitosamente
    event KipuBank_ExtraccionRealizada(address titular, uint monto);

    //@notice Error de extraccion
    error KipuBank_ExtraccionRechazada(address titular, uint monto);
    //@notice Error de Deposito
    error KipuBank_DepositoRechazado(address titular, uint monto);
    //@notice Error monto insuficiente
    error KipuBank_MontoInsuficiente(address titular, uint monto);

    //@notice constructor del contrato
    //@param _limite limite global que se permite por transaccion
    constructor(uint _limite) {
        bankCap = _limite;
        depositos = 0;
        retiros = 0;
        totalContrato = 0;
    }

    //@notice moficador para verificar los depositos
    modifier verificarDepositos(uint _monto) {
        if (_monto + totalContrato > bankCap) revert KipuBank_DepositoRechazado(msg.sender, _monto);
        _;
    }
    //@notice modificador para verificar los retiros
    modifier verificarRetiro(uint _monto) {
        if (_monto > umbral) revert KipuBank_ExtraccionRechazada(msg.sender, _monto);
        if (_monto > boveda[msg.sender]) revert KipuBank_ExtraccionRechazada(msg.sender, _monto);
        _;
    }
    //@notice funcion privada para realizar el retiro efectivo de fondos
    //@param _monto recibe el monto a retirar de la boveda
    function _retirarFondos(uint _monto) private {
        boveda[msg.sender] = boveda[msg.sender] - _monto;
        retiros = retiros + 1;
        totalContrato = totalContrato - _monto;
        
        emit KipuBank_ExtraccionRealizada(msg.sender, _monto);

        (bool succes, ) = payable(msg.sender).call{value: _monto}("");
        if (!succes) revert KipuBank_ExtraccionRechazada(msg.sender, _monto);
    }
    //@notice funcion externa para realizar el retiro de saldo
    //@param _monto es el monto a retirar de la boveda
    function retirarDeBoveda(uint _monto) external verificarRetiro(_monto) {
        _retirarFondos(_monto);
    }
    //@notice funcion para depositar en la boveda
    //@dev es payable y esa el modificador de verificarDepositos
    function depositarEnBoveda() external payable verificarDepositos(msg.value) {
        boveda[msg.sender] = boveda[msg.sender] + msg.value;        
        depositos = depositos + 1;
        totalContrato = totalContrato + msg.value;
        emit KipuBank_DepositoRealizado(msg.sender, msg.value);
    }
    //@notice funcion para ver el saldo guardado en el boveda
    function verBoveda() external view returns (uint monto_) {
        monto_ = boveda[msg.sender];
    }
}