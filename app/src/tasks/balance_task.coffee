
singletons = {}

class ledger.tasks.BalanceTask extends ledger.tasks.Task

  constructor: (accountIndex) ->
    super 'balance:' + accountIndex
    @_accountIndex = accountIndex

  onStart: () ->
    account = Account.find index: @_accountIndex
    totalBalance = account.get 'total_balance'
    unconfirmedBalance = account.get 'unconfirmed_balance'
    account = undefined
    ledger.api.BalanceRestClient.instance.getAccountBalance @_accountIndex, (balance, error) =>
      return unless @isRunning()
      if error?
        @emit "failure", @
        ledger.app.emit "wallet:balance:failed"
      else
        account = Account.find index: @_accountIndex
        account.set('total_balance', balance.total)
        account.set('unconfirmed_balance', balance.unconfirmed)
        account.save()
        @emit "success", @
        @stopIfNeccessary()
        if totalBalance != balance.total or unconfirmedBalance != balance.unconfirmed
          ledger.app.emit "wallet:balance:changed", account.get('wallet').getBalance()


  @get: (accountIndex) ->
    unless singletons[accountIndex]?
      singletons[accountIndex] = new @(accountIndex)
    singletons[accountIndex]

  @releaseAllBalanceTasks: -> singletons = {}