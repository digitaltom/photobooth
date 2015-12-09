photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$rootScope',
  function ($scope, $http, $uibModal, $log, $rootScope) {

    $scope.takePicture = function () {
      $scope.openShootModal();
      $http({
        method: 'POST',
        url: '/picture_sets.json'
      }).then(
        function successCallback(response) {
        $scope.closeShootModal();
        $scope.picture_sets.unshift(response.data);
      }, function errorCallback(response) {
        $scope.closeShootModal();
        //alert(response.data.error);
        $rootScope.alerts.push({type: 'danger', msg: response.data.error});
      }
      );
    };

    $scope.update = function () {
      $http({
        method: 'GET',
        url: '/picture_sets'
      }).then(function successCallback(response) {
        $scope.picture_sets = response.data;
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.closeAlert = function (index) {
      $rootScope.alerts.splice(index, 1);
    };

    $scope.openShootModal = function () {
      $scope.shootModalInstance = $uibModal.open({
        animation: true,
        templateUrl: 'picture_shoot.html'
      });
    };

    $scope.closeShootModal = function () {
      $scope.shootModalInstance.dismiss('cancel')
    }

    $log.log('Getting picture sets')
    $scope.update();

  }]);

