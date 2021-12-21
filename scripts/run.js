const main = async () => {
  const [owner, address1, address2] = await hre.ethers.getSigners()
  const personalDataManagerContractFactory = await hre.ethers.getContractFactory('PersonalDataManagerContract')
  const contract = await personalDataManagerContractFactory.deploy({
    value: hre.ethers.utils.parseEther('0.1'),
  })
  await contract.deployed()

  console.log('Contract deployed to:', contract.address)
  console.log('Contract deployed by:', owner.address)

  // events
  contract.on('BalanceChanged', (address, balance) => {
    console.log('BalanceChanged', address, balance)
  })
  contract.on('PersonalDataAdded', (evt) => {
    console.log('PersonalDataAdded', evt)
  })

  let txn, data
  txn = await contract.addPersonalData(
    10,
    'Oklakilome',
    '09303443213;09303443214',
    'ahmad@google.io;ahmad@google.com',
    'https://twitter.com/ahmad;https://linkedin.com/in/ahmad'
  )
  await txn.wait()
  console.log('')

  data = await contract.getFullPersonalData(owner.address)
  console.log('owner', 'getFullPersonalData()', data)
  console.log('')

  const address1Contract = contract.connect(address1)
  data = await address1Contract.getDataPrice(owner.address)
  console.log('address1', 'getDataPrice(address)', data.toString())
  console.log('')

  data = await address1Contract.getPointsBalance()
  console.log('address1', 'getPointsBalance()', data.toString())
  console.log('')

  try {
    txn = await address1Contract.getPersonalDataAccess(owner.address)
    await txn.wait()
  }
  catch (e) {
    console.log(e)
  }
  console.log('')

  data = await address1Contract.getFullPersonalData(owner.address)
  console.log('address1', 'getFullPersonalData(address)', data)
  console.log('')

  data = await address1Contract.getPointsBalance()
  console.log('address1', 'getPointsBalance()', data.toString())
  console.log('')

  try {
    txn = await address1Contract.getPersonalDataAccess(address2.address) // unknown address
    await txn.wait()
  }
  catch (e) {
    console.log(e)
  }

  try {
    console.log('Contract balance before withdraw:', (await contract.provider.getBalance(contract.address)).toString())
    console.log('Owner balance before withdraw:', (await owner.getBalance()).toString())
    console.log('Owner points balance before withdraw:', (await contract.getPointsBalance()).toString())
    txn = await contract.withdraw10()
    await txn.wait()
    console.log('')
    console.log('withdraw')
    console.log('')
    console.log('Contract balance after withdraw:', (await contract.provider.getBalance(contract.address)).toString())
    console.log('Owner balance after withdraw:', (await owner.getBalance()).toString())
    console.log('Owner points balance after withdraw:', (await contract.getPointsBalance()).toString())

    console.log('')
    console.log('')

    console.log('Contract balance before deposit:', (await contract.provider.getBalance(contract.address)).toString())
    console.log('Owner balance before deposit:', (await owner.getBalance()).toString())
    console.log('Owner points balance before deposit:', (await contract.getPointsBalance()).toString())
    txn = await contract.deposit({value: hre.ethers.utils.parseEther('0.01')})
    await txn.wait()
    console.log('')
    console.log('deposit')
    console.log('')
    console.log('Contract balance after deposit:', (await contract.provider.getBalance(contract.address)).toString())
    console.log('Owner balance after deposit:', (await owner.getBalance()).toString())
    console.log('Owner points balance after deposit:', (await contract.getPointsBalance()).toString())
  }
  catch (e) {
    console.error(e)
  }

  await new Promise(resolve => setTimeout(resolve, 5000))
};

const runMain = async () => {
  try {
    await main()
    process.exit(0)
  } catch (error) {
    console.log(error)
    process.exit(1)
  }
};

runMain()