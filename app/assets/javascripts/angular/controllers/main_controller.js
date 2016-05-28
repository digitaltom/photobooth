photoBoothApp.controller('MainCtrl', [
  '$scope',
  '$http',
  '$uibModal',
  '$log',
  '$rootScope',
  '$timeout',
  '$interval',
  function ($scope, $http, $uibModal, $log, $rootScope, $timeout, $interval) {

    $scope.takePicture = function () {

      $rootScope.current_shoot = 0;
      $rootScope.shoot_txt = 'Take pose!';
      $rootScope.shoot_progress_txt = '';
      $scope.openShootModal();

      var countdown_delay = 3000;

      $rootScope.shoot_progress = 100;
      countdown = $interval(function() {
        $rootScope.shoot_progress = $rootScope.shoot_progress - 5;
        if ($rootScope.shoot_progress <= 0) { $interval.cancel(countdown); }
      }, countdown_delay/20);

      $timeout(function() {
        $rootScope.shoot_txt = 'Action, taking 4 pictures';
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
      }, countdown_delay);


      // This fakes the progress in the modal. Change timeouts for
      // different camera settings

      $timeout(function() {
        $rootScope.current_shoot = 1;
        $rootScope.shoot_progress = 25;
        $rootScope.shoot_progress_txt = '1 / 4';
      }, 2000 + countdown_delay);
      $timeout(function() {
        $rootScope.current_shoot = 2;
        $rootScope.shoot_progress = 50;
        $rootScope.shoot_progress_txt = '2 / 4';
      }, 4000 + countdown_delay);
      $timeout(function() {
        $rootScope.current_shoot = 3;
        $rootScope.shoot_progress = 75;
        $rootScope.shoot_progress_txt = '3 / 4';
      }, 7000 + countdown_delay);
      $timeout(function() {
        $rootScope.current_shoot = 4;
        $rootScope.shoot_progress = 100;
        $rootScope.shoot_progress_txt = '4 / 4';
      }, 10000 + countdown_delay);
      $timeout(function() {
        $rootScope.current_shoot = 5;
        $rootScope.shoot_txt = 'Processing animation';
      }, 13000 + countdown_delay);

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

