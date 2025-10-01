//SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
/*
    @title KipuBank - un banco en blockchain
    @author Facundo Alejandro Caniza
*/
contract KipuBank {

    //@notice umbral para fijo para transaccion
    //@dev el umbral es arbitrario y debe ser establecido segun criterios
    uint immutable umbral;
    //@notice limite global de deposito
    uint immutable bankCap;
    //@notice cantidad de depositos del contrato
    uint private _depositos = 0;
    //@notice cantidad de retiros del contrato
    uint private _retiros = 0;
    //@notice total de ether depositado en el contrato
    uint private _totalContrato = 0;

    //@notice estructura que almacena por titular el monto que posee en la boveda
    mapping (address titular => uint monto) private _boveda;


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
    //@notice Error por sobrepasarse del limite
    error KipuBank_LimiteExcedido(uint monto);
    //@notice Error por saldo insuficiente
    error KipuBank_SaldoInsuficiente(address titular, uint monto);
    //@notice Error por umbral excedido
    error KipuBank_UmbralExcedido(uint monto);
    //@notice Error monto cero
    error KipuBank_MontoCero(address titular);

    //@notice constructor del contrato
    //@param _limite limite global que se permite por transaccion
    constructor(uint _limite) {
        bankCap = _limite;
        umbral = 50;
    }

    //@notice moficador para verificar los depositos
    modifier verificarDepositos(uint _monto) {
        if(_monto <= 0) revert KipuBank_MontoCero(msg.sender);
        if (_monto + _totalContrato >= bankCap) revert KipuBank_LimiteExcedido(_monto);
        _;
    }
    //@notice modificador para verificar los retiros
    //@dev el umbral solo se aplica a los retiros de boveda
    modifier verificarRetiro(uint _monto) {
        if(_monto <= 0) revert KipuBank_MontoCero(msg.sender);
        if (_monto > umbral) revert KipuBank_UmbralExcedido(_monto);
        if (_monto > _boveda[msg.sender]) revert KipuBank_SaldoInsuficiente(msg.sender, _monto);
        _;
    }
    //@notice funcion privada para realizar el retiro efectivo de fondos
    //@param _monto recibe el monto a retirar de la boveda
    function _retirarFondos(uint _monto) private {
        _boveda[msg.sender] -= _monto;
        _retiros++;
        _totalContrato -= _monto;
        
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
    //@dev es payable y usa el modificador de verificarDepositos
    function depositarEnBoveda() external payable verificarDepositos(msg.value) {
        _boveda[msg.sender] += msg.value;        
        _depositos++;
        _totalContrato += msg.value;
        emit KipuBank_DepositoRealizado(msg.sender, msg.value);
    }
    //@notice funcion para ver el saldo guardado en el boveda
    //@return monto_ devuelve el saldo depositado por cada address
    function verBoveda() external view returns (uint monto_) {
        monto_ = _boveda[msg.sender];
    }
    //@notice funcion para ver la totalidad de los depositos
    //@return devuelve la cantidad de depositos
    function verTotalDepositos() external view returns (uint) {
        return _depositos;
    }
    //@notice funcion para ver la totalidad de los retiros
    //@return devuelve la cantidad de retiros
    function verTotalRetiros() external view returns (uint) {
        return _retiros;
    }
    //@notice funcion para ver el saldo total del contrato
    //@return devuelve el saldo del contrato
    function verTotalContrato() external view returns (uint) {
        return _totalContrato;
    }

}