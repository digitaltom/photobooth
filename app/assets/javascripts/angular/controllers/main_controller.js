photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$rootScope',
  '$timeout',
  function ($scope, $http, $uibModal, $log, $rootScope, $timeout) {

    $scope.takePicture = function () {
      $rootScope.current_shoot = 0;
      $scope.openShootModal();
      $http({
        method: 'POST',
        url: '/picture_sets.json'
      }).then(
        function successCallback(response) {
          $scope.closeShootModal();
          $scope.picture_sets.unshift(response.data);
        },
        function errorCallback(response) {
          $scope.closeShootModal();
          $rootScope.alerts.push({type: 'danger', msg: response.data.error});
        }
      );

      // This fakes the progress in the modal. Change timeouts for
      // different camera settings
      $timeout(function() {
        $rootScope.current_shoot = 1;
        $rootScope.shoot_progress = '1 / 4';
      }, 1000);
      $timeout(function() {
        $rootScope.current_shoot = 2;
        $rootScope.shoot_progress = '2 / 4';
      }, 5000);
      $timeout(function() {
        $rootScope.current_shoot = 3;
        $rootScope.shoot_progress = '3 / 4';
      }, 8000);
      $timeout(function() {
        $rootScope.current_shoot = 4;
        $rootScope.shoot_progress = '4 / 4';
      }, 11000);
      $timeout(function() {
        $rootScope.current_shoot = 5;
        $rootScope.shoot_progress = 'Processing animation';
      }, 14000);

    };

    $scope.update = function () {
      $http({
        method: 'GET',
        url: '/picture_sets.json'
      }).then(function successCallback(response) {
        $scope.picture_sets = response.data;
      }, function errorCallback(response) {
        $rootScope.alerts.push({type: 'error', msg: response.data.error});
      });
    };

    $scope.openShootModal = function () {
      $scope.shootModalInstance = $uibModal.open({
        animation: true,
        size: 'lg',
        templateUrl: 'picture_shoot.html'
      });
    };

    $scope.closeShootModal = function () {
      $scope.shootModalInstance.dismiss('cancel')
    }

    $scope.update();

  }]);

